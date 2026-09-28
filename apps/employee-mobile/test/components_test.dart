import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/api.dart';
import 'package:defence_garden_employee/dwr_chat.dart';
import 'package:defence_garden_employee/ui/components.dart';
import 'package:defence_garden_employee/workspace.dart';

void main() {
  test('Indian rupee grouping from integer paise', () {
    expect(formatInr(3000000), '₹30,000.00');
    expect(formatInr('123456789'), '₹12,34,567.89');
    expect(formatInr(5), '₹0.05');
    expect(formatInr(-150000), '-₹1,500.00');
    expect(formatInr('x'), '—');
  });
  test('status labels are employee-facing and tones are not colour-only', () {
    expect(statusLabel('submitted'), 'Sent for review');
    expect(statusLabel('returned'), 'Needs changes');
    expect(statusTone('returned'), StatusTone.warning);
    expect(statusLabel('some_new_state'), 'some new state');
  });
  test('friendly errors replace transport codes', () {
    expect(
      friendlyError(const ApiFailure('OFFLINE', 'x')),
      contains('offline'),
    );
    expect(
      friendlyError(const ApiFailure('FORBIDDEN', 'x')),
      contains('access'),
    );
    expect(friendlyError(StateError('Check in first')), 'Check in first');
  });
  test(
    'DWR chat days: relative labels, honest preparing state and status pills',
    () {
      expect(dwrPreparingNow(null), isFalse);
      expect(
        dwrPreparingNow({
          'job': {'status': 'running'},
        }),
        isTrue,
      );
      final later = DateTime.now().add(const Duration(minutes: 9));
      expect(
        dwrPreparingNow({
          'job': {'status': 'queued', 'dueAt': later.toIso8601String()},
        }),
        isFalse,
        reason: 'The quiet-period wait is not shown as preparing',
      );
      expect(
        dwrPreparingNow({
          'job': {
            'status': 'queued',
            'dueAt': DateTime.now().toIso8601String(),
          },
        }),
        isTrue,
      );
      expect(dwrDayPill(null), isNull);
      expect(
        (dwrDayPill({
                  'report': {'status': 'submitted'},
                })!
                as StatusPill)
            .tone,
        StatusTone.info,
      );
    },
  );
  test('workspace epoch increments on every selection change', () {
    const a = WorkspaceSelection(siteId: 'a', epoch: 1);
    expect(a.siteId, 'a');
    expect(const WorkspaceSelection().siteId, isNull);
  });
}
