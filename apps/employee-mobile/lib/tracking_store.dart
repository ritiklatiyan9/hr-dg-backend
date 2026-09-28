import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'scope.dart';

/// SQLite runs off the UI isolate. Only sequence/state/size and opaque IDs are
/// plaintext. GPS, account, site, grant and payload are authenticated ciphertext.
class TrackingStore extends GeneratedDatabase {
  TrackingStore(
    super.executor,
    this.key, {
    this.file,
    this.keyName,
    this.storage,
  });
  final SecretKey key;
  final File? file;
  final String? keyName;
  final FlutterSecureStorage? storage;
  final cipher = AesGcm.with256bits();
  static const maxRecords = 20000, maxBytes = 16 * 1024 * 1024;
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE location_queue(seq INTEGER PRIMARY KEY AUTOINCREMENT,id TEXT NOT NULL UNIQUE,scope TEXT NOT NULL,state TEXT NOT NULL DEFAULT \'pending\',body BLOB NOT NULL)',
      );
      await customStatement(
        'CREATE INDEX location_queue_pending ON location_queue(state,seq)',
      );
      await customStatement(
        'CREATE INDEX location_queue_scope ON location_queue(scope,state,seq)',
      );
      await customStatement(
        'CREATE TABLE location_meta(id TEXT PRIMARY KEY,body BLOB NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE location_usage(id INTEGER PRIMARY KEY CHECK(id=1),records INTEGER NOT NULL,bytes INTEGER NOT NULL)',
      );
      await customStatement('INSERT INTO location_usage VALUES(1,0,0)');
      await customStatement(
        'CREATE TRIGGER location_added AFTER INSERT ON location_queue BEGIN UPDATE location_usage SET records=records+1,bytes=bytes+length(NEW.body) WHERE id=1; END',
      );
      await customStatement(
        'CREATE TRIGGER location_removed AFTER DELETE ON location_queue BEGIN UPDATE location_usage SET records=records-1,bytes=bytes-length(OLD.body) WHERE id=1; END',
      );
      await customStatement(
        'CREATE TRIGGER location_updated AFTER UPDATE OF body ON location_queue BEGIN UPDATE location_usage SET bytes=bytes+length(NEW.body)-length(OLD.body) WHERE id=1; END',
      );
    },
  );
  static Future<TrackingStore> open(
    String organization,
    String actor, {
    Directory? root,
    FlutterSecureStorage? secureStorage,
  }) async {
    final namespace = base64UrlEncode(
      (await Sha256().hash(utf8.encode('$organization:$actor'))).bytes,
    ).replaceAll('=', '');
    final base = root ?? await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'duty_location'));
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, '$namespace.sqlite'));
    final storage =
        secureStorage ??
        const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );
    final keyName = 'dg.tracking.$namespace';
    var encoded = await storage.read(key: keyName);
    if (encoded == null) {
      // A lost key cannot turn old ciphertext into retryable records.
      for (final suffix in ['', '-wal', '-shm']) {
        final old = File('${file.path}$suffix');
        if (await old.exists()) await old.delete();
      }
      encoded = base64Encode(
        await (await AesGcm.with256bits().newSecretKey()).extractBytes(),
      );
      await storage.write(key: keyName, value: encoded);
    }
    return TrackingStore(
      NativeDatabase.createInBackground(
        file,
        setup: (db) {
          db.execute('PRAGMA journal_mode=WAL');
          db.execute('PRAGMA synchronous=FULL');
          db.execute('PRAGMA busy_timeout=5000');
        },
      ),
      SecretKey(base64Decode(encoded)),
      file: file,
      keyName: keyName,
      storage: storage,
    );
  }

  Future<Uint8List> _seal(String id, Map<String, dynamic> value) async {
    final box = await cipher.encrypt(
      utf8.encode(jsonEncode(value)),
      secretKey: key,
      aad: utf8.encode('duty-location:$id:v1'),
    );
    return Uint8List.fromList([
      ...box.nonce,
      ...box.mac.bytes,
      ...box.cipherText,
    ]);
  }

  Future<Map<String, dynamic>> _open(String id, List<int> bytes) async {
    if (bytes.length < 28) throw StateError('Encrypted duty queue is damaged');
    final clear = await cipher.decrypt(
      SecretBox(
        bytes.sublist(28),
        nonce: bytes.sublist(0, 12),
        mac: Mac(bytes.sublist(12, 28)),
      ),
      secretKey: key,
      aad: utf8.encode('duty-location:$id:v1'),
    );
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
  }

  Future<String> siteKey(String site) async =>
      base64UrlEncode((await Sha256().hash(utf8.encode(site))).bytes);
  Future<void> saveContext(
    SiteScope scope,
    Map<String, dynamic> context,
  ) async {
    final id = await siteKey('${scope.siteId}:${scope.permissionVersion}');
    final body = await _seal(id, context);
    await customStatement(
      'INSERT INTO location_meta(id,body) VALUES(?,?) ON CONFLICT(id) DO UPDATE SET body=excluded.body',
      [id, body],
    );
  }

  Future<Map<String, dynamic>?> context(SiteScope scope) async {
    final id = await siteKey('${scope.siteId}:${scope.permissionVersion}');
    final row = await customSelect(
      'SELECT body FROM location_meta WHERE id=?',
      variables: [Variable(id)],
    ).getSingleOrNull();
    return row == null ? null : _open(id, row.read<Uint8List>('body'));
  }

  Future<void> enqueue(SiteScope scope, Map<String, dynamic> value) async {
    final id = value['sample']['clientId'] as String;
    final body = await _seal(id, value);
    final selector = await siteKey(scope.siteId);
    await transaction(() async {
      final used = await customSelect(
        'SELECT records,bytes FROM location_usage WHERE id=1',
      ).getSingle();
      if (used.read<int>('records') >= maxRecords ||
          used.read<int>('bytes') + body.length > maxBytes) {
        throw StateError(
          'Offline location storage is full. Reconnect to sync before recording more.',
        );
      }
      await customStatement(
        'INSERT INTO location_queue(id,scope,body) VALUES(?,?,?)',
        [id, selector, body],
      );
    });
  }

  Future<List<Map<String, dynamic>>> pending({int limit = 100}) async {
    final rows = await customSelect(
      'SELECT id,body FROM location_queue WHERE state=\'pending\' ORDER BY seq LIMIT ?',
      variables: [Variable(limit.clamp(1, 100))],
    ).get();
    return Future.wait(
      rows.map(
        (r) async => _open(r.read<String>('id'), r.read<Uint8List>('body')),
      ),
    );
  }

  Future<void> acknowledge(List<Map<String, dynamic>> results) async {
    await transaction(() async {
      for (final r in results) {
        final id = r['clientId'] as String;
        if (r['status'] == 'accepted') {
          await customStatement('DELETE FROM location_queue WHERE id=?', [id]);
        } else if (r['status'] == 'rejected') {
          final row = await customSelect(
            'SELECT body FROM location_queue WHERE id=?',
            variables: [Variable(id)],
          ).getSingleOrNull();
          if (row == null) continue;
          final value = await _open(id, row.read<Uint8List>('body'));
          value['rejection'] = r['reason'];
          await customStatement(
            'UPDATE location_queue SET state=\'rejected\',body=? WHERE id=?',
            [await _seal(id, value), id],
          );
        }
      }
    });
  }

  Future<({int pending, int rejected})> counts() async {
    final rows = await customSelect(
      'SELECT state,count(*) n FROM location_queue GROUP BY state',
    ).get();
    var pending = 0, rejected = 0;
    for (final r in rows) {
      if (r.read<String>('state') == 'pending') {
        pending = r.read<int>('n');
      } else {
        rejected = r.read<int>('n');
      }
    }
    return (pending: pending, rejected: rejected);
  }

  Future<void> destroy() async {
    await close();
    if (keyName != null) await storage!.delete(key: keyName!);
    if (file != null) {
      for (final suffix in ['', '-wal', '-shm']) {
        final f = File('${file!.path}$suffix');
        if (await f.exists()) await f.delete();
      }
    }
  }
}
