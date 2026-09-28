import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:defence_garden_employee/main.dart' as app;
import 'package:defence_garden_employee/mobile_ui.dart';
import 'support.dart';

/// Walks every ordinary authenticated route with the synthetic employee and
/// captures flat in-app screenshots. Asserts the bottom navigation is present
/// on each page and that no layout exception occurred.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('redesign route tour with persistent navigation', (tester) async {
    const password = String.fromEnvironment('TEST_PASSWORD');
    if (password.isEmpty) {
      throw StateError('Protected local test defines are required');
    }
    await const FlutterSecureStorage().delete(key: 'session');
    await app.main();
    await waitFor(tester, find.text('Sign in'));
    await binding.convertFlutterSurfaceToImage();
    await settle(tester, frames: 3);
    await binding.takeScreenshot('01-login');
    await signIn(tester, 'employee@example.test', password);
    try {
      await waitFor(tester, find.text('Daily Report'), tries: 150);
    } catch (_) {
      await binding.takeScreenshot('fail-after-login');
      rethrow;
    }
    final tour = <(String, String, String)>[
      ('/home', '10-home', 'Daily Report'),
      ('/work', '11-work', 'Daily work'),
      ('/work/attendance', '12-attendance', 'with photo'),
      ('/work/attendance/fix', '13-fix-attendance', 'Send for review'),
      ('/work/field-duty', '14-field-duty', 'Current site'),
      ('/work/daily-report', '15-daily-report', 'My DWR Agent|DWR chats'),
      ('/work/daily-report/chats', '15b-dwr-chats', 'DWR chats'),
      ('/work/tasks', '16-tasks', 'Today'),
      ('/work/leave', '17-leave', 'Balances'),
      ('/work/leave/apply', '18-apply-leave', 'Send for approval'),
      ('/work/records/expense', '19-expenses', 'Expenses'),
      ('/work/records/helpdesk', '20-helpdesk', 'Helpdesk'),
      ('/inbox', '21-inbox', 'All'),
      ('/me', '22-me', 'Personal'),
      ('/me/profile', '23-profile', 'Contact'),
      ('/me/records/payroll', '24-payslips', 'Payslips'),
      ('/me/records/document', '25-documents', 'Documents'),
      ('/me/settings', '26-settings', 'Dark theme'),
      ('/me/outbox', '27-outbox', 'Encrypted outbox'),
    ];
    for (final (route, name, marker) in tour) {
      app.router.go(route);
      await waitFor(
        tester,
        marker.contains('|')
            ? find.textContaining(RegExp(marker))
            : find.textContaining(marker),
      );
      await settle(tester, frames: 6);
      expect(find.byType(NavigationBar), findsOneWidget, reason: route);
      expect(tester.takeException(), isNull, reason: route);
      await binding.takeScreenshot(name);
    }
    app.router.go('/work/daily-report/reports');
    await waitFor(
      tester,
      find.textContaining(
        RegExp('Open DWR chat|Review & submit|View report|Continue draft'),
      ),
    );
    await settle(tester, frames: 4);
    final review = find.text('Review & submit');
    final draft = find.text('Continue draft');
    if (review.evaluate().isNotEmpty || draft.evaluate().isNotEmpty) {
      await tester.tap(review.evaluate().isNotEmpty ? review : draft);
      await waitFor(tester, find.text('Your report'));
      await settle(tester, frames: 6);
      expect(find.byType(NavigationBar), findsOneWidget);
      await binding.takeScreenshot('30-dwr-editor');
    } else {
      await binding.takeScreenshot('30-dwr-today-state');
    }
    await setDisplaySettings(dark: true);
    app.router.go('/home');
    await waitFor(tester, find.text('Daily Report'));
    await settle(tester, frames: 8);
    await binding.takeScreenshot('40-home-dark');
    app.router.go('/work');
    await waitFor(tester, find.text('Daily work'));
    await settle(tester, frames: 6);
    await binding.takeScreenshot('41-work-dark');
    await setDisplaySettings(dark: false, language: 'hi');
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    app.router.go('/home');
    await waitFor(tester, find.text('दैनिक रिपोर्ट'));
    await settle(tester, frames: 8);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('42-home-hindi-160');
    app.router.go('/work/attendance');
    await waitFor(tester, find.textContaining('फोटो से'));
    await settle(tester, frames: 6);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('43-attendance-hindi-160');
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await setDisplaySettings(language: 'en');
    app.router.go('/me');
    await waitFor(tester, find.text('Personal'));
    await scrollTo(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await waitFor(tester, find.text('Sign in'));
    expect(tester.takeException(), isNull);
  });
}
