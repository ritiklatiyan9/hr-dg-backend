import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:defence_garden_employee/main.dart' as app;
import 'package:defence_garden_employee/mobile_ui.dart';
import 'support.dart' as support;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'employee secure navigation with a persistent shell, safe request, Hindi dark and scaled text',
    (tester) async {
      const password = String.fromEnvironment('TEST_PASSWORD');
      if (password.isEmpty) {
        throw StateError('Protected local test defines are required');
      }
      await const FlutterSecureStorage().delete(key: 'session');
      await app.main();
      const adminOnly = bool.fromEnvironment('ADMIN_ONLY');
      if (!adminOnly) {
        await support.signIn(tester, 'employee@example.test', password);
        await support.waitFor(tester, find.text('Needs attention'));
        expect(find.byType(NavigationBar), findsOneWidget);
        await binding.convertFlutterSurfaceToImage();
        await support.settle(tester);
        await binding.takeScreenshot('flutter-home');
        await tester.tap(find.text('Work').last);
        await support.settle(tester);
        expect(find.text('Users & module access'), findsNothing);
        expect(find.text('Approvals'), findsNothing);
        expect(find.text('Daily work'), findsOneWidget);
        await binding.takeScreenshot('flutter-work');
        await tester.tap(find.text('Attendance').first);
        await support.waitFor(tester, find.textContaining('with photo'));
        expect(
          find.byType(NavigationBar),
          findsOneWidget,
          reason: 'bottom bar stays visible on detail pages',
        );
        await binding.takeScreenshot('flutter-attendance');
        await tester.tap(find.byType(BackButton));
        await support.settle(tester);
        await tester.tap(find.text('Me').last);
        await support.waitFor(tester, find.text('Arjun Mehta'));
        expect(find.text('42000.00'), findsNothing);
        expect(find.text('DEMO-ONLY-1234'), findsNothing);
        await binding.takeScreenshot('flutter-me');
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        await setDisplaySettings(language: 'hi', dark: true);
        await support.settle(tester);
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot('flutter-me-hindi-dark-scaled');
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await setDisplaySettings(language: 'en', dark: false);
        await support.settle(tester);
        await tester.tap(find.text('My Profile').first);
        await support.waitFor(
          tester,
          find.text('Request a phone number change'),
        );
        expect(find.text('42000.00'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Request a phone number change'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Request a phone number change'));
        await support.settle(tester);
        await tester.enterText(
          find.byType(TextFormField).first,
          '+91 9111111111',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'Flutter device verification only',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await support.settle(tester);
        await binding.takeScreenshot('flutter-profile-request');
        expect(
          find.byType(NavigationBar),
          findsOneWidget,
          reason: 'bottom bar stays visible on forms',
        );
        await tester.ensureVisible(find.text('Send request to HR'));
        await tester.tap(find.text('Send request to HR'));
        try {
          await support.waitFor(tester, find.text('Request sent to HR'));
        } catch (_) {
          await binding.takeScreenshot('fail-profile-request');
          rethrow;
        }
        await support.settle(tester);
        await tester.tap(find.text('Inbox').last);
        await support.settle(tester);
        await tester.tap(find.text('Requests').first);
        await support.settle(tester);
        for (var attempt = 0; attempt < 3; attempt++) {
          try {
            await support.waitFor(
              tester,
              find.text('Flutter device verification only'),
              tries: 50,
            );
            break;
          } catch (_) {
            if (attempt == 2) {
              await binding.takeScreenshot('fail-inbox-requests');
              rethrow;
            }
            // Pull to refresh the requests list and look again.
            await tester.fling(
              find.byType(Scrollable).first,
              const Offset(0, 400),
              1200,
            );
            await support.settle(tester, frames: 15);
          }
        }
        await support.settle(tester);
        await binding.takeScreenshot('flutter-inbox-requests');
        expect(find.text('Pending'), findsWidgets);
        expect(tester.takeException(), isNull);
        ScaffoldMessenger.of(
          tester.element(find.byType(NavigationBar)),
        ).clearSnackBars();
        await tester.pump(const Duration(seconds: 4));
        // The Me tab restores its own stack (My Profile, where the request was
        // opened from); reselecting the active tab returns it to the root.
        await tester.tap(find.text('Me').last);
        await support.settle(tester);
        if (find.text('Personal').evaluate().isEmpty) {
          await tester.tap(find.text('Me').last);
          await support.settle(tester);
        }
        try {
          await support.waitFor(tester, find.text('Personal'));
        } catch (_) {
          await binding.takeScreenshot('fail-me-tab');
          rethrow;
        }
        await tester.scrollUntilVisible(
          find.text('Sign out'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Sign out'));
        await support.waitFor(tester, find.text('Sign in'));
      }
      // A normal MFA-verified mobile session is prepared by the local fixture helper.
      const adminAccess = String.fromEnvironment('TEST_ADMIN_ACCESS');
      const adminRefresh = String.fromEnvironment('TEST_ADMIN_REFRESH');
      if (adminAccess.isEmpty || adminRefresh.isEmpty) {
        throw StateError('Run mobile-test-env before the device test');
      }
      await const FlutterSecureStorage().write(
        key: 'session',
        value: jsonEncode({
          'accessToken': adminAccess,
          'refreshToken': adminRefresh,
        }),
      );
      app.router.go('/');
      await support.chooseSiteIfAsked(tester);
      try {
        await support.waitFor(
          tester,
          find.textContaining(
            RegExp('Daily Report|Needs attention|checked in|Team'),
          ),
          tries: 150,
        );
      } catch (_) {
        await binding.takeScreenshot('fail-admin-home');
        rethrow;
      }
      await tester.tap(find.text('Work').last);
      await support.waitFor(tester, find.text('Daily work'));
      await tester.scrollUntilVisible(
        find.text('Users & module access'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Users & module access'));
      await support.waitFor(tester, find.text('Aditi Sharma'));
      await tester.tap(find.text('Aditi Sharma'));
      await support.waitFor(tester, find.text('Role template'));
      await support.settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      await binding.takeScreenshot('flutter-access-editor');
      final salary = find.byKey(const ValueKey('employees.field.salary:null'));
      await tester.scrollUntilVisible(
        salary,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(salary);
      await support.settle(tester);
      await tester.tap(find.text('Deny').last);
      await support.settle(tester);
      final reason = find.byType(TextField).last;
      await tester.scrollUntilVisible(
        reason,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        reason,
        'Device preview only: verify salary restrictions',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await support.settle(tester);
      await tester.ensureVisible(find.text('Preview changes'));
      await tester.tap(find.text('Preview changes'));
      await support.waitFor(tester, find.text('Review access changes'));
      await support.settle(tester);
      await binding.takeScreenshot('flutter-access-preview');
      expect(find.textContaining('Explicit deny'), findsWidgets);
      await tester.tap(find.text('Keep editing'));
      await support.settle(tester);
      await tester.tap(find.byType(BackButton));
      await support.settle(tester);
      await tester.tap(find.byType(BackButton));
      await support.settle(tester);
      await tester.scrollUntilVisible(
        find.text('People'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('People'));
      await support.waitFor(tester, find.text('Arjun Mehta'));
      await support.settle(tester);
      await binding.takeScreenshot('flutter-people');
      await tester.tap(find.text('Me').last);
      await support.settle(tester);
      if (find.text('Personal').evaluate().isEmpty) {
        await tester.tap(find.text('Me').last);
        await support.settle(tester);
      }
      await support.waitFor(tester, find.text('Personal'));
      await tester.scrollUntilVisible(
        find.text('Sign out'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sign out'));
      await support.waitFor(tester, find.text('Sign in'));
      expect(tester.takeException(), isNull);
    },
  );
}
