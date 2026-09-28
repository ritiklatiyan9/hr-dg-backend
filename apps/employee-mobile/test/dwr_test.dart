import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/dwr_chat.dart';
import 'package:defence_garden_employee/dwr_screen.dart';
import 'package:defence_garden_employee/operation_vault.dart';
import 'package:defence_garden_employee/providers.dart';
import 'package:defence_garden_employee/scope.dart';
import 'package:defence_garden_employee/mobile_ui.dart';
import 'support/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('dark theme text and labels retain readable contrast', () {
    final theme = employeeTheme(Brightness.dark);
    expect(
      theme.textTheme.bodyMedium!.color!.computeLuminance(),
      greaterThan(0.5),
    );
    expect(
      theme.inputDecorationTheme.labelStyle!.color!.computeLuminance(),
      greaterThan(0.4),
    );
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('a blank DWR states nothing rather than claiming none', () {
    expect(blankDwr()['stated']['pending'], 'not_stated');
    expect(blankDwr()['completed'], isEmpty);
  });
  testWidgets(
    'DWR agent chat shows the month by day and sends from the native keyboard with an idempotent client ID',
    (tester) async {
      final api = FakeApi();
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: employeeTheme(Brightness.light),
            home: const DwrChatPage(
              scope: SiteScope('org-1', 'actor-1', 3, 'site-dg'),
              groupId: null,
              landing: true,
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Pump room ka valve replace kiya'), findsOneWidget);
      expect(find.text('Storage tank cleaning complete'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      final composer = find.byKey(const ValueKey('dwr-composer'));
      final field = tester.widget<TextField>(composer);
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.maxLength, dwrMessageMax);
      await tester.enterText(composer, '  Shaam ko safety meeting attend ki  ');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final write = api.writes.last;
      expect(write['operation'], 'message');
      final input = write['input'] as Map;
      expect(input['body'], 'Shaam ko safety meeting attend ki');
      expect(input['groupId'], isNull);
      expect(input['clientId'], matches(RegExp(r'^[0-9a-f-]{36}$')));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'offline DWR persists original site and pending state encrypted without submitting',
    (tester) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('dwr-widget-');
        addTearDown(() => root.delete(recursive: true));
        final vault = await OperationVault.open('org', 'actor', root: root);
        await tester.binding.setSurfaceSize(const Size(800, 3000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: DwrEditor(
                scope: const SiteScope('org', 'actor', 7, 'site-one'),
                report: {
                  'isSelf': true,
                  'status': 'draft',
                  'version': 0,
                  'work_date': '2026-09-21',
                  'content': blankDwr(),
                  'attachments': [],
                },
                data: {
                  'site': {'name': 'Original site'},
                  'settings': {'offline_drafts': true},
                },
                caps: const [
                  'my_dwr.view',
                  'my_dwr.create',
                  'my_dwr.edit',
                  'my_dwr.submit',
                ],
                vault: vault,
                offline: true,
              ),
            ),
          ),
        );
        final field = find.byKey(const ValueKey('dwr-field-completed'));
        await tester.ensureVisible(field);
        await tester.enterText(field, 'Checked records.');
        final save = find.text('Save encrypted local draft');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        final stored = await vault.read('dwr_site-one_2026-09-21');
        expect(stored!['siteId'], 'site-one');
        expect(stored['state'], 'saved_locally');
        expect(stored['content']['completed'], ['Checked records.']);
        expect(
          (await vault.entries()),
          isEmpty,
          reason: 'DWR draft cannot enter automatic attendance sync',
        );
        final bytes = await File(
          '${vault.directory.path}/dwr_site-one_2026-09-21.enc',
        ).readAsBytes();
        expect(
          utf8.decode(bytes, allowMalformed: true),
          isNot(contains('Checked records.')),
        );
        final reopened = await OperationVault.open('org', 'actor', root: root);
        expect(await reopened.read('dwr_site-one_2026-09-21'), stored);
        final other = await OperationVault.open('org', 'other', root: root);
        expect(await other.entries(includeDwr: true), isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await vault.destroy();
        expect(await vault.directory.exists(), false);
      });
    },
  );
}
