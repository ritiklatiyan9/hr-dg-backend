import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:defence_garden_employee/main.dart';
import 'package:defence_garden_employee/mobile_ui.dart';
import 'vault_native_test.dart' as vault;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  vault.main();
  testWidgets('profile login form interactions with large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: employeeTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await binding.watchPerformance(() async {
      for (var i = 0; i < 5; i++) {
        await tester.enterText(
          find.byType(TextField).first,
          'synthetic@example.test',
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '');
        await tester.pumpAndSettle();
      }
    }, reportKey: 'login_form_profile');
    expect(tester.takeException(), isNull);
  });
}
