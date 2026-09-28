import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/hr_services.dart';

void main() {
  test('payslip payment pill follows the server balance, not the status', () {
    String? label(Map<String, dynamic> r) => paymentPill(r)?.label;
    expect(label({'duePaise': null, 'paidPaise': '0'}), isNull);
    expect(label({'duePaise': '3000000', 'paidPaise': '0'}), 'Payment pending');
    expect(label({'duePaise': '1', 'paidPaise': '2999999'}), 'Part paid');
    expect(label({'duePaise': '0', 'paidPaise': '3000000'}), 'Paid');
    expect(label({'duePaise': '-100', 'paidPaise': '3000100'}), 'Paid');
  });
}
