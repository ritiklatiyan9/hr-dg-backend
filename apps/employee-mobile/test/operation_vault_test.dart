import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:defence_garden_employee/operation_vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'encrypted relaunch retains original scope; tamper and account switching are isolated',
    () async {
      final root = await Directory.systemTemp.createTemp('dg-vault-');
      addTearDown(() => root.delete(recursive: true));
      final vault = await OperationVault.open('org', 'actor', root: root);
      final payload = {
        'id': 'event-one',
        'siteId': 'original-site',
        'actorId': 'actor',
        'createdAt': '2026-09-21',
        'photo': 'sensitive-synthetic-photo',
        'state': 'saved_locally',
      };
      await vault.write('event-one', payload);
      final file = File('${vault.directory.path}/event-one.enc');
      final bytes = await file.readAsBytes();
      expect(
        utf8.decode(bytes, allowMalformed: true),
        isNot(contains('sensitive-synthetic-photo')),
      );
      final reopened = await OperationVault.open('org', 'actor', root: root);
      expect(await reopened.read('event-one'), payload);
      final other = await OperationVault.open(
        'org',
        'different-actor',
        root: root,
      );
      expect(await other.entries(), isEmpty);
      bytes[bytes.length - 1] ^= 1;
      await file.writeAsBytes(bytes);
      await expectLater(reopened.read('event-one'), throwsA(anything));
      await reopened.destroy();
      expect(
        await const FlutterSecureStorage().read(key: reopened.keyName),
        isNull,
      );
      expect(await reopened.directory.exists(), false);
      final signedInAgain = await OperationVault.open(
        'org',
        'actor',
        root: root,
      );
      expect(await signedInAgain.entries(), isEmpty);
    },
  );
  test(
    'lost secure key destroys unreadable queue, serialization preserves all entries',
    () async {
      final root = await Directory.systemTemp.createTemp('dg-vault-');
      addTearDown(() => root.delete(recursive: true));
      final vault = await OperationVault.open('org', 'actor', root: root);
      await Future.wait(
        List.generate(
          12,
          (i) => vault.write('event-$i', {'id': 'event-$i', 'createdAt': '$i'}),
        ),
      );
      expect((await vault.entries()).length, 12);
      await const FlutterSecureStorage().delete(key: vault.keyName);
      final restored = await OperationVault.open('org', 'actor', root: root);
      expect(await restored.entries(), isEmpty);
    },
  );
}
