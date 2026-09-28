import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:defence_garden_employee/main.dart' as app;
import 'support.dart' as support;

/// Records frame timelines while scrolling Home and switching tabs. Run in
/// profile mode on a physical device; the driver writes a summary JSON.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('home scroll and tab switch frame timing', (tester) async {
    const password = String.fromEnvironment('TEST_PASSWORD');
    if (password.isEmpty) {
      throw StateError('Protected local test defines are required');
    }
    await const FlutterSecureStorage().delete(key: 'session');
    await app.main();
    await support.signIn(tester, 'employee@example.test', password);
    await support.waitFor(tester, find.text('Daily Report'), tries: 150);
    await tester.pump(const Duration(seconds: 2));
    await binding.traceAction(() async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 4; i++) {
        await tester.fling(list, const Offset(0, -500), 1800);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.fling(list, const Offset(0, 500), 1800);
        await tester.pump(const Duration(milliseconds: 700));
      }
    }, reportKey: 'home_scroll');
    await binding.traceAction(() async {
      for (final label in ['Work', 'Inbox', 'Me', 'Home', 'Work', 'Home']) {
        await tester.tap(find.text(label).last);
        await tester.pump(const Duration(milliseconds: 600));
      }
    }, reportKey: 'tab_switch');
    app.router.go('/work/attendance');
    await support.waitFor(tester, find.text('History'));
    await binding.traceAction(() async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -400), 1500);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.fling(list, const Offset(0, 400), 1500);
        await tester.pump(const Duration(milliseconds: 700));
      }
    }, reportKey: 'attendance_scroll');
    expect(tester.takeException(), isNull);
  });
}
