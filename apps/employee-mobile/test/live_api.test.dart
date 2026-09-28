import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/api.dart';
import 'package:defence_garden_employee/scope.dart';
import 'package:defence_garden_employee/graphql/schema.graphql.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This explicitly invoked integration test uses the real local API; widget
  // tests keep Flutter's default network isolation.
  HttpOverrides.global = null;
  test(
    'Flutter enforces self service and persists a safe request across the real API',
    () async {
      const password = String.fromEnvironment('TEST_PASSWORD');
      if (password.isEmpty) {
        throw StateError(
          'Use --dart-define-from-file with local test credentials',
        );
      }
      FlutterSecureStorage.setMockInitialValues({});
      final api = HrApi(baseUrl: 'http://127.0.0.1:4000');
      try {
        await api.login('employee@example.test', password);
        final bootstrap = (await api.bootstrap()).bootstrap;
        expect(bootstrap.sites.length, 2);
        final first = SiteScope(
          bootstrap.organization.id,
          bootstrap.actor.id,
          bootstrap.actor.permissionVersion,
          '20000000-0000-4000-8000-000000000001',
        );
        final second = SiteScope(
          bootstrap.organization.id,
          bootstrap.actor.id,
          bootstrap.actor.permissionVersion,
          '20000000-0000-4000-8000-000000000002',
        );
        final profile = (await api.profile(first)).myProfile!;
        final original = profile.phone;
        expect(profile.salary, isNull);
        expect(profile.bank, isNull);
        final caps = (await api.capabilities(first)).scope.capabilities;
        expect(caps, contains('my_hr.submit'));
        expect(caps, isNot(contains('employees.view')));
        await expectLater(
          api.update(first, profile.id, '+91 9111111111', profile.version),
          throwsA(isA<StateError>()),
        );
        final request = await api.foundationWrite(
          first,
          'request_profile',
          Input$FoundationInput(
            phone: '+91 9111111111',
            reason: 'Flutter live API verification only',
            expectedVersion: profile.version,
          ),
        );
        expect(request.saveFoundation.status, 'pending');
        expect(
          (await api.requests(first)).profileRequests.any(
            (r) => r.id == request.saveFoundation.id && r.status == 'pending',
          ),
          isTrue,
        );
        await api.switchSite();
        final other = (await api.profile(second)).myProfile!;
        expect(other.phone, original);
        expect(other.id, profile.id);

        await api.refresh();
        expect((await api.bootstrap()).bootstrap.actor.id, bootstrap.actor.id);
        await api.logout();
        expect(await api.storage.read(key: 'session'), isNull);
      } finally {
        api.dispose();
      }
    },
  );
}
