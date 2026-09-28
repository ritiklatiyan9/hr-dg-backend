import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:defence_garden_employee/operation_vault.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native secure key, encrypted reopen, tamper and logout lifecycle',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Native encrypted outbox verification')),
        ),
      );
      final vault = await OperationVault.open(
        'synthetic-native-test',
        'synthetic-actor',
      );
      await vault.write('offline-event', {
        'id': 'offline-event',
        'siteId': 'original-site',
        'createdAt': '2026-09-21',
        'photo': 'PRIVATE_TEST_EVIDENCE',
        'state': 'saved_locally',
      });
      final ciphertext = await File(
        '${vault.directory.path}/offline-event.enc',
      ).readAsBytes();
      expect(
        utf8.decode(ciphertext, allowMalformed: true),
        isNot(contains('PRIVATE_TEST_EVIDENCE')),
      );
      final reopened = await OperationVault.open(
        'synthetic-native-test',
        'synthetic-actor',
      );
      expect(
        (await reopened.read('offline-event'))?['siteId'],
        'original-site',
      );
      expect(
        await const FlutterSecureStorage().read(key: reopened.keyName),
        isNotNull,
      );
      final another = await OperationVault.open(
        'synthetic-native-test',
        'other-actor',
      );
      expect(await another.entries(), isEmpty);
      ciphertext[ciphertext.length - 1] ^= 1;
      await File(
        '${vault.directory.path}/offline-event.enc',
      ).writeAsBytes(ciphertext);
      await expectLater(reopened.read('offline-event'), throwsA(anything));
      await reopened.destroy();
      await another.destroy();
      expect(
        await const FlutterSecureStorage().read(key: reopened.keyName),
        isNull,
      );
      expect(await reopened.directory.exists(), false);
    },
  );
}
