import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:defence_garden_employee/api.dart';
import 'package:defence_garden_employee/providers.dart';
import 'package:defence_garden_employee/hr_services.dart';
import 'package:defence_garden_employee/scope.dart';
import 'package:defence_garden_employee/mobile_ui.dart';
import 'package:defence_garden_employee/graphql/operations.graphql.dart';
import 'support.dart' as support;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native published payroll and employee → HR → employee helpdesk with persisted acknowledgment',
    (tester) async {
      const site = '20000000-0000-4000-8000-000000000001',
          org = '10000000-0000-4000-8000-000000000001';
      final api = HrApi();
      await api.login(
        'employee@example.test',
        const String.fromEnvironment('TEST_PASSWORD'),
      );
      final boot = (await api.bootstrap()).bootstrap;
      final scope = SiteScope(
        org,
        boot.actor.id,
        boot.actor.permissionVersion,
        site,
      );
      GoRouter router(String initial) => GoRouter(
        initialLocation: initial,
        routes: [
          GoRoute(
            path: '/me/records/:kind',
            builder: (c, s) =>
                RecordsPage(scope: scope, kind: s.pathParameters['kind']!),
            routes: [
              GoRoute(
                path: ':id',
                builder: (c, s) => RecordDetailPage(
                  scope: scope,
                  kind: s.pathParameters['kind']!,
                  id: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      );
      Future<void> show(String kind, {bool dark = false}) async {
        displaySettings.value = DisplaySettings(
          language: dark ? 'hi' : 'en',
          dark: dark,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiProvider.overrideWithValue(api)],
            child: MaterialApp.router(
              key: ValueKey('$kind:$dark'),
              theme: employeeTheme(dark ? Brightness.dark : Brightness.light),
              themeAnimationDuration: Duration.zero,
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(
                  ctx,
                ).copyWith(textScaler: TextScaler.linear(dark ? 1.4 : 1)),
                child: child!,
              ),
              routerConfig: router('/me/records/$kind'),
            ),
          ),
        );
      }

      await show('payroll');
      await support.waitFor(
        tester,
        find.textContaining(RegExp('Published|प्रकाशित')),
      );
      await tester.tap(find.textContaining(RegExp('Published|प्रकाशित')).first);
      await support.waitFor(
        tester,
        find.textContaining(RegExp('Net pay|शुद्ध वेतन')),
      );
      expect(
        find.text('₹30,000.00'),
        findsNothing,
        reason: 'net pay hidden by default',
      );
      await tester.tap(find.byTooltip('Show amount'));
      await support.settle(tester);
      expect(find.text('₹30,000.00'), findsWidgets);
      await binding.convertFlutterSurfaceToImage();
      await support.settle(tester);
      await binding.takeScreenshot('flutter-payroll');
      await show('payroll', dark: true);
      await support.waitFor(
        tester,
        find.textContaining(RegExp('Published|प्रकाशित')),
      );
      await tester.tap(find.textContaining(RegExp('Published|प्रकाशित')).first);
      await support.waitFor(
        tester,
        find.textContaining(RegExp('Net pay|शुद्ध वेतन')),
      );
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('flutter-payroll-hindi-dark-scaled');
      final response = await api.scopedWrite(
        scope,
        documentNodeMutationHrCommand,
        {
          'operation': 'save',
          'input': {
            'clientId': const Uuid().v4(),
            'expectedVersion': 0,
            'kind': 'helpdesk',
            'payload': {
              'subject':
                  'Synthetic native follow-up ${DateTime.now().millisecondsSinceEpoch}',
              'category': 'Test workflow',
              'description':
                  'Synthetic persisted employee-to-HR-to-employee request',
            },
            'note': 'Synthetic native workflow test',
          },
        },
      );
      var record = Map<String, dynamic>.from(response['hrCommand']);
      await show('helpdesk');
      await support.waitFor(
        tester,
        find.textContaining('Synthetic native follow-up'),
      );
      await tester.tap(find.textContaining('Synthetic native follow-up').first);
      await support.waitFor(tester, find.text('Details'));
      Future<void> act(String label) async {
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, label),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.widgetWithText(FilledButton, label));
        await support.settle(tester);
        await tester.enterText(
          find.byType(TextField).last,
          'Synthetic native confirmed $label',
        );
        await support.settle(tester);
        await tester.tap(find.widgetWithText(FilledButton, label).last);
        await support.settle(tester);
      }

      await act('Send to HR');
      await support.waitFor(tester, find.text('Sent for review'));
      await binding.takeScreenshot('flutter-helpdesk-submitted');
      final admin = HrApi();
      admin.access = const String.fromEnvironment('TEST_ADMIN_ACCESS');
      final ab = (await admin.bootstrap()).bootstrap,
          ascope = SiteScope(
            org,
            ab.actor.id,
            ab.actor.permissionVersion,
            site,
          );
      final snapshot = await admin.scopedRead(
        ascope,
        documentNodeQueryHrRecords,
        {'kind': 'helpdesk'},
      );
      record = Map<String, dynamic>.from(
        (snapshot['hrRecords']['records'] as List).firstWhere(
          (r) => r['id'] == record['id'],
        ),
      );
      for (final action in ['start', 'resolve']) {
        final result = await admin.scopedWrite(
          ascope,
          documentNodeMutationHrCommand,
          {
            'operation': 'action',
            'input': {
              'id': record['id'],
              'expectedVersion': record['version'],
              'clientId': const Uuid().v4(),
              'action': action,
              'note': 'Synthetic independent HR $action',
            },
          },
        );
        record = Map<String, dynamic>.from(result['hrCommand']);
      }
      await tester.tap(find.byIcon(Icons.refresh));
      await support.waitFor(
        tester,
        find.widgetWithText(FilledButton, 'Close request'),
      );
      await act('Close request');
      await support.waitFor(tester, find.text('Closed'));
      await binding.takeScreenshot('flutter-helpdesk-resolved');
      final finalState = await api.scopedRead(
        scope,
        documentNodeQueryHrRecords,
        {'kind': 'helpdesk'},
      );
      expect(
        (finalState['hrRecords']['records'] as List).firstWhere(
          (r) => r['id'] == record['id'],
        )['status'],
        'closed',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await api.logout();
      api.dispose();
      admin.dispose();
    },
  );
}
