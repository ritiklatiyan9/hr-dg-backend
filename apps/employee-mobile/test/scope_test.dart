import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/scope.dart';

void main() {
  test('late response is rejected after site switch', () {
    final epoch = ScopeEpoch();
    final old = epoch.capture();
    epoch.change();
    expect(epoch.isCurrent(old), isFalse);
    expect(epoch.isCurrent(epoch.capture()), isTrue);
  });
  test(
    'cache keys include actor, organization, site and permission version',
    () {
      const first = SiteScope('org', 'actor', 1, 'defence');
      expect(first, isNot(const SiteScope('org', 'actor', 1, 'river')));
      expect(first, isNot(const SiteScope('org', 'other', 1, 'defence')));
      expect(first, isNot(const SiteScope('other', 'actor', 1, 'defence')));
      expect(first, isNot(const SiteScope('org', 'actor', 2, 'defence')));
    },
  );
}
