import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    'native reviewer reads and approves employee report with fresh server acknowledgment',
    (tester) async {
      const access = String.fromEnvironment('TEST_ADMIN_ACCESS'),
          refresh = String.fromEnvironment('TEST_ADMIN_REFRESH');
      expect(refresh, isNotEmpty);
      await const FlutterSecureStorage().write(
        key: 'session',
        value: jsonEncode({'accessToken': access, 'refreshToken': refresh}),
      );
      final api = HrApi();
      expect(await api.restore(), true);
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
      const viewOnly = bool.fromEnvironment('DWR_VIEW_ONLY');
      var report = Map<String, dynamic>.from(
        (data['reports'] as List).firstWhere(
          (r) =>
              r['status'] == (viewOnly ? 'approved' : 'submitted') &&
              (r['content']['completed'] as List).contains(
                'Synthetic native DWR relaunch check.',
              ),
        ),
      );
      expect(report['provenanceVisible'], false);
      final caps = (await api.capabilities(scope)).scope.capabilities;
      final vault = await OperationVault.open(
        scope.organizationId,
        scope.actorId,
      );
      final pendingBefore = (await vault.entries(
        includeDwr: true,
      )).where((r) => r['operation'] == 'dwr_draft').length;
      Future<void> show(bool dark) async {
        displaySettings.value = DisplaySettings(
          language: dark ? 'hi' : 'en',
          dark: dark,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiProvider.overrideWithValue(api)],
            child: MaterialApp(
              themeAnimationDuration: Duration.zero,
              theme: employeeTheme(dark ? Brightness.dark : Brightness.light),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(dark ? 1.4 : 1)),
                child: child!,
              ),
              home: DwrEditor(
                key: ValueKey(dark),
                scope: scope,
                report: report,
                data: data,
                caps: caps,
                vault: vault,
                offline: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(false);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('flutter-dwr-review');
      if (!viewOnly) {
        final reason = find.descendant(
          of: find.byKey(const ValueKey('dwr-reason')),
          matching: find.byType(TextField),
        );
        await tester.scrollUntilVisible(
          reason,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(reason);
        await tester.enterText(
          reason,
          'Synthetic native independent DWR review.',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        final approve = find.text('Approve');
        await tester.scrollUntilVisible(
          approve,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(approve);
        await tester.tap(approve);
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          final updated =
              (await api.scopedRead(scope, documentNodeQueryDwr))['dwr'] as Map;
          report = Map<String, dynamic>.from(
            (updated['reports'] as List).firstWhere(
              (r) => r['id'] == report['id'],
            ),
          );
          if (report['status'] == 'approved') {
            break;
          }
        }
        expect(report['status'], 'approved');
      }
      expect(
        (await vault.entries(
          includeDwr: true,
        )).where((r) => r['operation'] == 'dwr_draft').length,
        pendingBefore,
        reason:
            'Online review must not create a local draft or queued approval',
      );
      expect((report['history'] as List).first['event'], 'approve');
      await show(true);
      await binding.takeScreenshot('flutter-dwr-hindi-dark-scaled');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      displaySettings.value = const DisplaySettings();
    },
  );
}
