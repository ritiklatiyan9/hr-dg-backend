import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/main.dart';
import 'package:defence_garden_employee/ui/tokens.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildEmployeeTheme(Brightness.light),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('phone login exposes the complete secure sign-in form', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(390, 844));

    expect(find.text('Organization ID'), findsNothing);
    expect(find.text('Email ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('PEOPLE & HR'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet login uses the branded split layout without overflow', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1024, 800));

    expect(find.text('Defence Garden'), findsOneWidget);
    expect(find.text('Your workday,\nall in one place.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
