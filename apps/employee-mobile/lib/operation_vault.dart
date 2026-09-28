import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Authenticated application-level encryption. Drift is not assumed encrypted.
/// Scope, payload, photo bytes and sync metadata are all inside the ciphertext.
class OperationVault {
  OperationVault._(this.directory, this.keyName, this.storage);
  final Directory directory;
  final String keyName;
  final FlutterSecureStorage storage;
  final cipher = AesGcm.with256bits();
  Future<void> _tail = Future.value();
  bool destroyed = false;
  static Future<OperationVault> open(
    String organization,
    String actor, {
    Directory? root,
    FlutterSecureStorage? secureStorage,
  }) async {
    final hash = await Sha256().hash(utf8.encode('$organization:$actor'));
    final namespace = base64UrlEncode(hash.bytes).replaceAll('=', '');
    final base = root ?? await getApplicationSupportDirectory();
    final directory = Directory(
      p.join(base.path, 'encrypted_outbox', namespace),
    );
    await directory.create(recursive: true);
    final vault = OperationVault._(
      directory,
      'dg.outbox.$namespace',
      secureStorage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          ),
    );
    if (await vault.storage.read(key: vault.keyName) == null) {
      // If the key was lost, old ciphertext cannot be safely retried under a new key.
      for (final file in directory.listSync()) {
        if (file is File) await file.delete();
      }
      final secret = await vault.cipher.newSecretKey();
      await vault.storage.write(
        key: vault.keyName,
        value: base64Encode(await secret.extractBytes()),
      );
    }
    return vault;
  }

  Future<T> serialized<T>(Future<T> Function() work) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await work());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<SecretKey> _key() async {
    if (destroyed) throw StateError('Local account was signed out');
    final value = await storage.read(key: keyName);
    if (value == null) throw StateError('Local encryption key is unavailable');
    return SecretKey(base64Decode(value));
  }

  Future<void> write(String id, Map<String, dynamic> payload) =>
      serialized(() async {
        if (!RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(id)) {
          throw ArgumentError('Invalid queue identifier');
        }
        final bytes = utf8.encode(jsonEncode(payload));
        final existing = File(p.join(directory.path, '$id.enc'));
        var used = 0;
        await for (final entry in directory.list()) {
          if (entry is File && entry.path != existing.path) {
            used += await entry.length();
          }
        }
        if (used + bytes.length + 28 > 128 * 1024 * 1024) {
          throw StateError(
            'Encrypted outbox reached its 128 MB limit; synchronize first',
          );
        }
        final box = await cipher.encrypt(
          bytes,
          secretKey: await _key(),
          aad: utf8.encode('$keyName:$id:v1'),
        );
        final target = File(p.join(directory.path, '$id.enc')),
            temporary = File(p.join(directory.path, '$id.tmp'));
        await temporary.writeAsBytes([
          ...box.nonce,
          ...box.mac.bytes,
          ...box.cipherText,
        ], flush: true);
        if (destroyed) {
          await temporary.delete();
          throw StateError('Account changed');
        }
        await temporary.rename(target.path);
      });
  Future<Map<String, dynamic>?> read(String id) => serialized(() async {
    final file = File(p.join(directory.path, '$id.enc'));
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length < 28) throw StateError('Local encrypted data is damaged');
    final clear = await cipher.decrypt(
      SecretBox(
        bytes.sublist(28),
        nonce: bytes.sublist(0, 12),
        mac: Mac(bytes.sublist(12, 28)),
      ),
      secretKey: await _key(),
      aad: utf8.encode('$keyName:$id:v1'),
    );
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
  });
  Future<List<Map<String, dynamic>>> entries({bool includeDwr = false}) async {
    final files = await directory
        .list()
        .where(
          (f) =>
              f.path.endsWith('.enc') &&
              !f.path.endsWith('/context.enc') &&
              (includeDwr || !p.basename(f.path).startsWith('dwr_')),
        )
        .toList();
    final result = <Map<String, dynamic>>[];
    for (final file in files) {
      final row = await read(p.basenameWithoutExtension(file.path));
      if (row != null) result.add(row);
    }
    result.sort((a, b) => '${a['createdAt']}'.compareTo('${b['createdAt']}'));
    return result;
  }

  Future<void> remove(String id) => serialized(() async {
    final file = File(p.join(directory.path, '$id.enc'));
    if (await file.exists()) await file.delete();
  });
  Future<void> destroy() => serialized(() async {
    destroyed = true;
    await storage.delete(key: keyName);
    if (await directory.exists()) await directory.delete(recursive: true);
  });
}
