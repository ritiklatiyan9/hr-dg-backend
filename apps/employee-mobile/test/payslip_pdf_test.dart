import 'dart:convert';
import 'package:defence_garden_employee/payslip_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> design(String layout, {bool all = true}) => {
  'title': 'Salary Slip',
  'companyName': '',
  'companyAddress': 'Plot 1\nGurugram',
  // 1×1 PNG, the same data-URL form the server stores.
  'logo':
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  'accent': '#1E6B4B',
  'layout': layout,
  'show': {
    for (final k in [
      'employeeCode',
      'designation',
      'department',
      'legalEmployer',
      'revision',
      'payments',
      'amountInWords',
      'notes',
      'signature',
    ])
      k: all,
  },
  'signatory': 'Payroll Lead',
  'signatoryTitle': 'Authorised signatory',
  'footer': 'Computer generated.',
};
final payslip = jsonDecode('''{
  "id": "r1", "start": "2026-09-01", "finish": "2026-09-30", "revision": 1,
  "publishedOn": "2026-09-30", "paidPaise": "1000000", "jobTitle": "Engineer", "department": null,
  "snapshot": {"lines": [
    {"label": "Base", "kind": "earning", "calculatedPaise": "3000000"},
    {"label": "OT", "kind": "overtime", "calculatedPaise": "50000"},
    {"label": "Advance", "kind": "deduction", "calculatedPaise": "100000"}],
    "grossPaise": "3050000", "deductionPaise": "100000", "netPaise": "2950000",
    "employeeName": "Asha", "employeeCode": "DG-9", "legalEmployer": "Demo Pvt Ltd",
    "assumptions": "Synthetic", "policyVersion": "P1"},
  "payments": [{"kind": "payment", "paise": "1000000", "method": "upi", "reference": "UTR1", "paidOn": "2026-10-01"}]
}''') as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('payslip words and periods match the web renderer', () {
    expect(amountInWords('3000000'), 'Rupees Thirty Thousand Only');
    expect(
      amountInWords('12345678950'),
      'Rupees Twelve Crore Thirty Four Lakh Fifty Six Thousand Seven Hundred Eighty Nine and Fifty Paise Only',
    );
    expect(payslipPeriod('2026-02-01', '2026-02-28'), 'February 2026');
    expect(payslipPeriod('2026-09-01', '2026-09-15'), '1 Sep 2026 – 15 Sep 2026');
  });
  for (final layout in ['classic', 'modern', 'compact']) {
    test('builds a $layout payslip PDF', () async {
      final bytes = await buildPayslipPdf(design(layout), payslip);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      final plain = await buildPayslipPdf(design(layout, all: false), payslip);
      expect(plain.length, lessThan(bytes.length));
    });
  }
}
