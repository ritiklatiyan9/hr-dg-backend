import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bounded real-time pumping. Never uses pumpAndSettle: live timers such as
/// the checked-in clock keep scheduling frames by design.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int tries = 100,
}) async {
  for (var i = 0; i < tries; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

/// Signs in on the login screen and selects Defence Garden if asked.
Future<void> signIn(WidgetTester tester, String email, String password) async {
  await waitFor(tester, find.text('Sign in'));
  await tester.enterText(find.byKey(const ValueKey('login-email')), email);
  await tester.enterText(
    find.byKey(const ValueKey('login-password')),
    password,
  );
  // Dismiss the keyboard so the button is not covered, then bring it on screen.
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester, frames: 4);
  final button = find.widgetWithText(FilledButton, 'Sign in');
  await tester.ensureVisible(button);
  await settle(tester, frames: 2);
  await tester.tap(button);
  await chooseSiteIfAsked(tester);
}

Future<void> chooseSiteIfAsked(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    final choose = find.widgetWithText(FilledButton, 'Choose site');
    if (choose.evaluate().isNotEmpty) {
      await tester.tap(choose);
      await settle(tester, frames: 8);
      await tester.tap(find.text('Defence Garden').last);
      await settle(tester, frames: 8);
      return;
    }
    if (find.text('Needs attention').evaluate().isNotEmpty) return;
  }
}

Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 250,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await settle(tester, frames: 3);
}
