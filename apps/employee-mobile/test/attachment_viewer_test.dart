import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:defence_garden_employee/app_router.dart' as app;
import 'shell_test.dart' show start, settle, stop, loadFonts;
import 'support/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('locally generated PDFs open in the viewer from route extra', (
    tester,
  ) async {
    await start(tester, FakeApi());
    app.router.go(
      '/me/attachment/payslip-1?type=application/pdf&title=Payslip',
      extra: Uint8List.fromList('%PDF-1.4 synthetic'.codeUnits),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(PdfPreview), findsOneWidget);
    await stop(tester);
  });
}
