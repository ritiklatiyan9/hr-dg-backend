import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:defence_garden_employee/api.dart';
import 'package:defence_garden_employee/dwr_screen.dart';
import 'package:defence_garden_employee/operation_vault.dart';
import 'package:defence_garden_employee/providers.dart';
import 'package:defence_garden_employee/scope.dart';
import 'package:defence_garden_employee/mobile_ui.dart';
import 'package:defence_garden_employee/graphql/operations.graphql.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'DWR encrypted draft survives process relaunch and submits only after confirmation',
    (tester) async {
      const stage = String.fromEnvironment(
        'DWR_STAGE',
        defaultValue: 'capture',
      );
      final api = HrApi();
      if (stage == 'capture') {
        await api.login(
          'employee@example.test',
          const String.fromEnvironment('TEST_PASSWORD'),
        );
      } else {
        expect(await api.restore(), true);
      }
      final b = (await api.bootstrap()).bootstrap;
      final scope = SiteScope(
        b.organization.id,
        b.actor.id,
        b.actor.permissionVersion,
        '20000000-0000-4000-8000-000000000001',
      );
      final data = Map<String, dynamic>.from(
        (await api.scopedRead(scope, documentNodeQueryDwr))['dwr'],
      );
      final caps = (await api.capabilities(scope)).scope.capabilities;
      final vault = await OperationVault.open(
        scope.organizationId,
        scope.actorId,
      );
      expect(data['settings']['offline_drafts'], true);
      Map<String, dynamic> report;
      if (stage == 'capture') {
        final used = (data['reports'] as List)
            .map((r) => r['work_date'])
            .toSet();
        var date = DateTime.parse(
          data['workDate'],
        ).subtract(const Duration(days: 50));
        while (used.contains(date.toIso8601String().substring(0, 10))) {
          date = date.subtract(const Duration(days: 1));
        }
        report = {
          'isSelf': true,
          'status': 'draft',
          'version': 0,
          'work_date': date.toIso8601String().substring(0, 10),
          'content': blankDwr(),
          'attachments': [],
        };
        await api.storage.write(
          key: 'offline_identity',
          value: jsonEncode({
            'organizationId': scope.organizationId,
            'actorId': scope.actorId,
          }),
        );
      } else {
        final saved = (await vault.entries(includeDwr: true))
            .where(
              (r) =>
                  r['operation'] == 'dwr_draft' &&
                  (r['content']['completed'] as List).contains(
                    'Synthetic native DWR relaunch check.',
                  ),
            )
            .last;
        expect(saved['siteId'], scope.siteId);
        report = {
          ...Map<String, dynamic>.from(saved['report']),
          'content': saved['content'],
          'pendingRequest': saved['pendingRequest'],
        };
      }
      Future<void> showEditor(bool offline) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiProvider.overrideWithValue(api)],
            child: MaterialApp(
              theme: employeeTheme(Brightness.light),
              home: DwrEditor(
                key: ValueKey(offline),
                scope: scope,
                report: report,
                data: data,
                caps: caps,
                vault: vault,
                offline: offline,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await showEditor(true);
      final field = find.byKey(const ValueKey('dwr-field-completed'));
      await tester.scrollUntilVisible(
        field,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(field);
      if (stage == 'capture') {
        await tester.enterText(field, 'Synthetic native DWR relaunch check.');
        await tester.testTextInput.receiveAction(TextInputAction.done);
      } else {
        expect(
          (tester.widget<TextField>(field)).controller!.text,
          'Synthetic native DWR relaunch check.',
        );
      }
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('flutter-dwr-$stage-editor');
      final local = find.text('Save encrypted local draft');
      await tester.scrollUntilVisible(
        local,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(local);
      await tester.tap(local);
      await tester.pumpAndSettle();
      final localId = 'dwr_${scope.siteId}_${report['work_date']}';
      final saved = await vault.read(localId);
      expect(saved!['state'], 'saved_locally');
      expect(
        (await vault.entries()).where((r) => r['operation'] == 'dwr_draft'),
        isEmpty,
      );
      final cipher = await File(
        '${vault.directory.path}/$localId.enc',
      ).readAsBytes();
      expect(
        utf8.decode(cipher, allowMalformed: true),
        isNot(contains('Synthetic native DWR')),
      );
      await binding.takeScreenshot('flutter-dwr-$stage-local');
      if (stage != 'capture') {
        await showEditor(false);
        final submit = find.text('Submit DWR');
        await tester.scrollUntilVisible(
          submit,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text('Confirm submission'), findsOneWidget);
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        List reports = [];
        for (var attempt = 0; attempt < 30; attempt++) {
          await tester.pump(const Duration(milliseconds: 200));
          final snapshot =
              (await api.scopedRead(scope, documentNodeQueryDwr))['dwr'] as Map;
          reports = (snapshot['reports'] as List)
              .where(
                (r) =>
                    r['work_date'] == report['work_date'] &&
                    r['isSelf'] == true,
              )
              .toList();
          if (reports.length == 1 && reports.single['status'] == 'submitted') {
            break;
          }
        }
        expect(reports.length, 1);
        expect(reports.single['status'], 'submitted');
        expect(await vault.read(localId), null);
        await tester.scrollUntilVisible(
          find.text('Sent for review').first,
          -400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Sent for review').first);
        await binding.takeScreenshot('flutter-dwr-submitted');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
