import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/tracking_store.dart';
import 'package:defence_garden_employee/scope.dart';

const scope = SiteScope('org', 'actor', 1, 'site');
Map<String, dynamic> row(String id) => {
  'sample': {'clientId': id, 'latitude': 28.612345, 'longitude': 77.2},
  'siteId': 'site',
  'actorId': 'actor',
  'grantId': 'grant',
};
void main() {
  test(
    'ciphertext queue paginates, acknowledges per record, preserves rejected evidence and counters',
    () async {
      final store = TrackingStore(
        NativeDatabase.memory(),
        await AesGcm.with256bits().newSecretKey(),
      );
      await store.enqueue(scope, row('one'));
      await store.enqueue(scope, row('two'));
      await store.enqueue(scope, row('three'));
      final raw = await store
          .customSelect('SELECT body FROM location_queue LIMIT 1')
          .getSingle();
      expect(
        utf8.decode(raw.read<List<int>>('body'), allowMalformed: true),
        isNot(contains('latitude')),
      );
      expect(await store.counts(), (pending: 3, rejected: 0));
      expect(
        (await store.pending(limit: 1)).single['sample']['clientId'],
        'one',
      );
      await store.acknowledge([
        {'clientId': 'one', 'status': 'accepted'},
        {'clientId': 'two', 'status': 'rejected', 'reason': 'UPLOAD_EXPIRED'},
      ]);
      expect(await store.counts(), (pending: 1, rejected: 1));
      expect((await store.pending()).single['sample']['clientId'], 'three');
      expect(
        (await store
                .customSelect('SELECT records FROM location_usage')
                .getSingle())
            .read<int>('records'),
        2,
      );
      await store.saveContext(scope, {'private': 'downloaded window'});
      expect((await store.context(scope))!['private'], 'downloaded window');
      expect(
        await store.context(const SiteScope('org', 'actor', 2, 'site')),
        isNull,
      );
      expect(
        await store.context(const SiteScope('org', 'actor', 1, 'another-site')),
        isNull,
      );
      await store.close();
    },
  );
  test(
    'storage limit refuses additional capture without dropping existing pending records',
    () async {
      final store = TrackingStore(
        NativeDatabase.memory(),
        await AesGcm.with256bits().newSecretKey(),
      );
      await store.enqueue(scope, row('preserved'));
      await store.customStatement('UPDATE location_usage SET records=20000');
      await expectLater(
        store.enqueue(scope, row('overflow')),
        throwsStateError,
      );
      expect((await store.pending()).single['sample']['clientId'], 'preserved');
      await store.close();
    },
  );
  test('tampered ciphertext cannot be decoded as a location', () async {
    final store = TrackingStore(
      NativeDatabase.memory(),
      await AesGcm.with256bits().newSecretKey(),
    );
    await store.enqueue(scope, row('one'));
    await store.enqueue(scope, row('two'));
    await store.customStatement(
      "UPDATE location_queue SET body=(SELECT body FROM location_queue WHERE id='one') WHERE id='two'",
    );
    await expectLater(
      store.pending(),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    await store.close();
  });
}
