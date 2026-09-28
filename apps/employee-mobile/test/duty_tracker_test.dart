import 'dart:async';
import 'dart:io';
import 'package:defence_garden_employee/api.dart';
import 'package:defence_garden_employee/tracking_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gql/ast.dart';
import 'package:defence_garden_employee/duty_tracker.dart';
import 'package:defence_garden_employee/scope.dart';
import 'support/fake_api.dart';

const scope = SiteScope('org', 'actor', 1, 'site');
const notice = 'Location is shared during HR assigned shifts.';

class TrackingApi extends FakeApi {
  bool active = true, configured = true;
  int leaseSeconds = 120, staleSeconds = 120;
  String disclosure = notice;
  Completer<Map<String, dynamic>>? delayed;
  @override
  Future<Map<String, dynamic>> scopedWrite(
    SiteScope scope,
    DocumentNode document,
    Map<String, dynamic> variables,
  ) async {
    if (variables['operation'] == 'offlinePermit') return {};
    return super.scopedWrite(scope, document, variables);
  }

  @override
  Future<Map<String, dynamic>> scopedRead(
    SiteScope scope,
    DocumentNode document, [
    Map<String, dynamic> variables = const {},
  ]) async {
    if (delayed != null) return delayed!.future;
    final now = DateTime.now().toUtc();
    return {
      'trackingContext': {
        'serverTime': now.toIso8601String(),
        'configured': configured,
        'locationRules': {'maxAccuracyM': 25, 'freshnessSeconds': 30},
        'policy': {
          'enabled': true,
          'version': 1,
          'notice': disclosure,
          'sample_seconds': 15,
          'stale_seconds': staleSeconds,
        },
        'window': active
            ? {
                'id': 'shift',
                'version': 1,
                'starts_at': now
                    .subtract(const Duration(hours: 1))
                    .toIso8601String(),
                'ends_at': now.add(const Duration(hours: 1)).toIso8601String(),
              }
            : null,
        'leaseUntil': now
            .add(Duration(seconds: leaseSeconds))
            .toIso8601String(),
      },
    };
  }
}

class OfflineTrackingApi extends TrackingApi {
  bool offline = false, loseAck = false;
  int uploads = 0;
  final stored = <String>{};
  final heartbeats = <Map<String, dynamic>>[];
  DateTime grantEnd = DateTime.now().add(const Duration(hours: 1));
  DateTime? grantStart;
  @override
  Future<Map<String, dynamic>> scopedRead(
    SiteScope s,
    DocumentNode d, [
    Map<String, dynamic> v = const {},
  ]) async {
    if (offline) {
      throw const ApiFailure('OFFLINE', 'Synthetic internet interruption');
    }
    final data = await super.scopedRead(s, d, v);
    if (grantStart != null) {
      final context = data['trackingContext'] as Map;
      context['upcomingWindow'] = {
        ...context['window'] as Map,
        'starts_at': grantStart!.toUtc().toIso8601String(),
      };
      context['window'] = null;
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> scopedWrite(
    SiteScope s,
    DocumentNode d,
    Map<String, dynamic> v,
  ) async {
    if (offline) {
      throw const ApiFailure('OFFLINE', 'Synthetic internet interruption');
    }
    if (v['operation'] == 'offlinePermit') {
      return {
        'trackingCommand': {
          'id': 'grant',
          'roster_id': 'shift',
          'roster_version': 1,
          'policy_version': 1,
          'starts_at':
              (grantStart ??
                      DateTime.now().subtract(const Duration(seconds: 1)))
                  .toUtc()
                  .toIso8601String(),
          'ends_at': grantEnd.toUtc().toIso8601String(),
        },
      };
    }
    if (v['operation'] == 'heartbeat') {
      heartbeats.add(Map<String, dynamic>.from(v['input'] as Map));
      return {
        'trackingCommand': {'status': 'accepted'},
      };
    }
    if (v['operation'] == 'batch') {
      uploads++;
      final rows = v['input']['samples'] as List;
      stored.addAll(rows.map((p) => p['clientId'] as String));
      if (loseAck) {
        loseAck = false;
        throw const ApiFailure('UNCONFIRMED', 'Synthetic lost acknowledgement');
      }
      return {
        'trackingCommand': {
          'results': rows
              .map(
                (p) => {
                  'clientId': p['clientId'],
                  'status': 'accepted',
                  'reason': null,
                },
              )
              .toList(),
        },
      };
    }
    return super.scopedWrite(s, d, v);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'duty_tracking:org:actor:site': notice,
    }),
  );
  test(
    'automatic shift start, stop at roster end and restart next shift without attendance',
    () async {
      final api = TrackingApi();
      final stream = StreamController<Position>.broadcast();
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        positionStream: (_) => stream.stream,
      );
      await tracker.bind(scope);
      expect(tracker.tracking, true);
      api.active = false;
      await tracker.refresh();
      expect(tracker.tracking, false);
      expect(tracker.authorized, false);
      api.active = true;
      await tracker.refresh();
      expect(tracker.tracking, true);
      await tracker.close();
      await stream.close();
      api.dispose();
    },
  );
  test(
    'duty time with location off asks for location, then starts once it is on',
    () async {
      final api = TrackingApi();
      final stream = StreamController<Position>.broadcast();
      var available = false;
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => available,
        positionStream: (_) => stream.stream,
      );
      await tracker.bind(scope);
      expect(tracker.tracking, false);
      expect(tracker.needsLocation, true);
      expect(tracker.status, contains('Turn on location'));
      available = true;
      await tracker.refresh();
      expect(tracker.tracking, true);
      expect(tracker.needsLocation, false);
      await tracker.close();
      await stream.close();
      api.dispose();
    },
  );
  test(
    'lease timer stops sharing even without a position callback or network',
    () async {
      final api = TrackingApi()..leaseSeconds = 2;
      final stream = StreamController<Position>.broadcast();
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        positionStream: (_) => stream.stream,
      );
      await tracker.bind(scope);
      expect(tracker.tracking, true);
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(tracker.tracking, false);
      expect(tracker.authorized, false);
      await tracker.close();
      await stream.close();
      api.dispose();
    },
  );
  test(
    'late scope response cannot activate collection after sign-out',
    () async {
      final api = TrackingApi()..delayed = Completer();
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        positionStream: (_) => const Stream.empty(),
      );
      final waiting = tracker.bind(scope);
      await Future<void>.delayed(Duration.zero);
      await tracker.bind(null);
      api.delayed!.complete({'trackingContext': {}});
      await waiting;
      expect(tracker.scope, null);
      expect(tracker.authorization, null);
      expect(tracker.tracking, false);
      await tracker.close();
      api.dispose();
    },
  );
  test(
    'new disclosure or disabling on device prevents automatic restart',
    () async {
      final api = TrackingApi();
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        positionStream: (_) => const Stream.empty(),
      );
      await tracker.bind(scope);
      expect(tracker.tracking, true);
      api.disclosure = 'A changed HR disclosure requiring acknowledgement';
      await tracker.refresh();
      expect(tracker.tracking, false);
      expect(tracker.enabledOnDevice, false);
      api.disclosure = notice;
      await tracker.refresh();
      expect(tracker.tracking, true);
      await tracker.disable();
      await tracker.refresh();
      expect(tracker.tracking, false);
      expect(tracker.enabledOnDevice, false);
      await tracker.close();
      api.dispose();
    },
  );
  test(
    'background window waits for resume and withdrawn GPS permission prevents startup',
    () async {
      final api = TrackingApi();
      bool available = false;
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => available,
        positionStream: (_) => const Stream.empty(),
      );
      tracker.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tracker.bind(scope);
      expect(tracker.tracking, false);
      tracker.foreground = true;
      await tracker.refresh();
      expect(tracker.tracking, false);
      available = true;
      await tracker.refresh();
      expect(tracker.tracking, true);
      await tracker.close();
      api.dispose();
    },
  );
  test(
    'low battery hysteresis, quality gates and scope rebinding keep valid uploads isolated',
    () async {
      final api = TrackingApi();
      var level = 18;
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => level,
        locationAvailable: () async => true,
        positionStream: (_) => const Stream.empty(),
      );
      await tracker.bind(scope);
      expect(tracker.sampler!.lowBattery, true);
      expect(tracker.sampler!.intervalSeconds, 30);
      expect(tracker.sampler!.maxAccuracyM, 25);
      for (final value in [22, 26]) {
        level = value;
        tracker.lastBatteryRead = null;
        await tracker.refresh();
        expect(tracker.sampler!.lowBattery, value == 22);
      }
      Position position(double accuracy) => Position(
        latitude: 28.6,
        longitude: 77.2,
        timestamp: DateTime.now().toUtc(),
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      await tracker.send(position(100), tracker.generation, scope);
      expect(api.writes, isEmpty);
      await tracker.send(position(5), tracker.generation, scope);
      expect(api.writes, hasLength(1));
      expect(api.writes.single['site'], scope.siteId);
      expect(api.writes.single['input']['latitude'], 28.6);
      await tracker.send(position(5), tracker.generation, scope);
      expect(api.writes, hasLength(1));
      await tracker.bind(const SiteScope('org', 'actor', 2, 'site'));
      expect(tracker.tracking, true);
      expect(tracker.sampler, isNotNull);
      await tracker.close();
      api.dispose();
    },
  );
  test(
    'pending location startup cannot revive after the lease or scope is stopped',
    () async {
      final api = TrackingApi();
      final permission = Completer<bool>();
      var starts = 0;
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () => permission.future,
        positionStream: (_) {
          starts++;
          return const Stream.empty();
        },
      );
      final binding = tracker.bind(scope);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tracker.bind(null);
      permission.complete(true);
      await binding;
      expect(starts, 0);
      expect(tracker.tracking, false);
      await tracker.close();
      api.dispose();
    },
  );
  test(
    'offline positions survive restart, sync after reconnect and retry lost acknowledgements exactly once',
    () async {
      final root = await Directory.systemTemp.createTemp('duty-offline-test');
      final api = OfflineTrackingApi();
      DutyTracker make() => DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        positionStream: (_) => const Stream.empty(),
        openStore: (s) =>
            TrackingStore.open(s.organizationId, s.actorId, root: root),
      );
      var tracker = make();
      await tracker.bind(scope);
      expect(tracker.offlineGrant, isNotNull);
      expect(
        DateTime.parse(tracker.cachedContext!['savedAt'] as String).isUtc,
        true,
      );
      api.offline = true;
      await tracker.refresh();
      expect(tracker.tracking, true);
      for (var i = 0; i < 3; i++) {
        tracker.sampler!.attempted(const Duration(seconds: -60));
        final p = Position(
          latitude: 28.6,
          longitude: 77.2,
          timestamp: DateTime.now().toUtc(),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        await tracker.send(p, tracker.generation, scope);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(tracker.queuedCount, 3);
      expect(api.stored, isEmpty);
      await tracker.close();
      tracker = make();
      await tracker.bind(scope);
      expect(tracker.tracking, true);
      expect(tracker.queuedCount, 3);
      while (tracker.syncingQueue) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      api.offline = false;
      api.loseAck = true;
      await tracker.syncQueue(force: true);
      expect(api.stored, hasLength(3));
      expect(tracker.queuedCount, 3);
      await tracker.syncQueue(force: true);
      expect(api.stored, hasLength(3));
      expect(tracker.queuedCount, 0);
      expect(api.uploads, 2);
      await tracker.close();
      api.dispose();
      await root.delete(recursive: true);
    },
  );
  test(
    'offline capture stops at downloaded duty end without another GPS fix',
    () async {
      final root = await Directory.systemTemp.createTemp('duty-expiry-test');
      final api = OfflineTrackingApi()
        ..grantEnd = DateTime.now().add(const Duration(seconds: 2));
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        positionStream: (_) => const Stream.empty(),
        openStore: (s) =>
            TrackingStore.open(s.organizationId, s.actorId, root: root),
      );
      await tracker.bind(scope);
      api.offline = true;
      await tracker.refresh();
      expect(tracker.tracking, true);
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(tracker.tracking, false);
      expect(tracker.authorized, false);
      await tracker.close();
      api.dispose();
      await root.delete(recursive: true);
    },
  );
  test(
    'a pre-downloaded future shift starts offline while app is visible, never before duty',
    () async {
      final root = await Directory.systemTemp.createTemp('duty-future-test');
      final api = OfflineTrackingApi()
        ..grantStart = DateTime.now().add(const Duration(seconds: 2));
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        positionStream: (_) => const Stream.empty(),
        openStore: (s) =>
            TrackingStore.open(s.organizationId, s.actorId, root: root),
      );
      await tracker.bind(scope);
      expect(tracker.offlineGrant, isNotNull);
      expect(tracker.tracking, false);
      expect(tracker.authorized, false);
      api.offline = true;
      await Future<void>.delayed(const Duration(seconds: 3));
      await tracker.refresh();
      expect(tracker.tracking, true);
      expect(tracker.authorized, true);
      await tracker.close();
      api.dispose();
      await root.delete(recursive: true);
    },
  );
  test(
    'a still phone heartbeats on its schedule poll so HR sees it connected, not lost',
    () async {
      final root = await Directory.systemTemp.createTemp('duty-heartbeat-test');
      final api = OfflineTrackingApi();
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => true,
        // Stationary: the OS delivers no position callbacks at all.
        positionStream: (_) => const Stream.empty(),
        openStore: (s) =>
            TrackingStore.open(s.organizationId, s.actorId, root: root),
      );
      Future<void> settle() async {
        while (tracker.syncingQueue || tracker.heartbeating) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      await tracker.bind(scope);
      await settle();
      expect(tracker.tracking, true);
      expect(tracker.pollSeconds, 30);
      expect(api.heartbeats, [
        {'grantId': 'grant', 'state': 'tracking'},
      ]);
      final savedAt = tracker.cachedContext!['savedAt'];
      await tracker.refresh();
      await settle();
      expect(api.heartbeats, hasLength(1), reason: 'recent contact suffices');
      expect(
        tracker.cachedContext!['savedAt'],
        savedAt,
        reason: 'an unchanged context is not re-encrypted every poll',
      );
      // 65 s = stale 120 - 25 - poll 30: the worst gap stays under HR's threshold.
      tracker.lastContact =
          tracker.samplingClock.elapsed - const Duration(seconds: 66);
      await tracker.refresh();
      await settle();
      expect(api.heartbeats, hasLength(2));
      await tracker.close();
      api.dispose();
      await root.delete(recursive: true);
    },
  );
  test(
    'duty time with device location off is reported to HR as location off',
    () async {
      final root = await Directory.systemTemp.createTemp('duty-off-test');
      final api = OfflineTrackingApi()..staleSeconds = 60;
      final tracker = DutyTracker(
        api,
        batteryLevel: () async => 80,
        locationAvailable: () async => false,
        positionStream: (_) => const Stream.empty(),
        openStore: (s) =>
            TrackingStore.open(s.organizationId, s.actorId, root: root),
      );
      await tracker.bind(scope);
      while (tracker.syncingQueue || tracker.heartbeating) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(tracker.needsLocation, true);
      expect(tracker.pollSeconds, 17);
      expect(api.heartbeats.single['state'], 'location_off');
      await tracker.close();
      api.dispose();
      await root.delete(recursive: true);
    },
  );
}
