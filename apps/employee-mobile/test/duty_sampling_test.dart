import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:defence_garden_employee/duty_sampling.dart';

final epoch = DateTime.utc(2026, 9, 25, 9);
Position fix(
  int t, {
  double latitude = 28.6,
  double accuracy = 5,
  double speed = 0,
  double speedAccuracy = 0,
  bool mocked = false,
}) => Position(
  longitude: 77.2,
  latitude: latitude,
  timestamp: epoch.add(Duration(seconds: t)),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: speed,
  speedAccuracy: speedAccuracy,
  isMocked: mocked,
);
DutySampling sampler({int base = 30, int stale = 120}) => DutySampling(
  baseSeconds: base,
  staleSeconds: stale,
  maxAccuracyM: 50,
  freshnessSeconds: 60,
);
bool observe(
  DutySampling s,
  int t, {
  double latitude = 28.6,
  double accuracy = 5,
  double speed = 0,
  double speedAccuracy = 0,
}) => s.observe(
  fix(
    t,
    latitude: latitude,
    accuracy: accuracy,
    speed: speed,
    speedAccuracy: speedAccuracy,
  ),
  Duration(seconds: t),
  epoch.add(Duration(seconds: t)),
);
void main() {
  test(
    '90 seconds and multiple precise fixes enter stationary; GPS jitter does not create movement',
    () {
      final s = sampler();
      for (final t in [0, 30, 60, 90]) {
        expect(observe(s, t, latitude: 28.6 + (t == 60 ? 0.00004 : 0)), true);
      }
      expect(s.motion, DutyMotion.stationary);
      expect(s.intervalSeconds, 60);
      s.attempted(const Duration(seconds: 90));
      expect(s.due(const Duration(seconds: 149)), false);
      expect(s.due(const Duration(seconds: 150)), true);
    },
  );
  test(
    'two displaced fixes resume movement; a single uncertain fix cannot flap modes',
    () {
      final s = sampler();
      for (final t in [0, 30, 60, 90]) {
        observe(s, t);
      }
      observe(s, 120, latitude: 28.6003);
      expect(s.motion, DutyMotion.stationary);
      observe(s, 150, latitude: 28.6006);
      expect(s.motion, DutyMotion.moving);
      expect(s.intervalSeconds, 30);
    },
  );
  test(
    'credible speed resumes immediately; unknown speed accuracy is not evidence',
    () {
      final s = sampler();
      for (final t in [0, 30, 60, 90]) {
        observe(s, t);
      }
      observe(s, 120, speed: 2);
      expect(s.motion, DutyMotion.stationary);
      observe(s, 150, speed: 2, speedAccuracy: 0.3);
      expect(s.motion, DutyMotion.moving);
    },
  );
  test(
    'bad, duplicate, mocked, stale, future and impossible jumps never become valid samples',
    () {
      final s = sampler();
      expect(observe(s, 0), true);
      expect(observe(s, 0), false);
      expect(observe(s, 1, latitude: 45), false);
      expect(observe(s, 30, accuracy: 100), false);
      expect(
        s.observe(
          fix(30, mocked: true),
          const Duration(seconds: 30),
          epoch.add(const Duration(seconds: 30)),
        ),
        false,
      );
      expect(
        s.observe(
          fix(30),
          const Duration(seconds: 100),
          epoch.add(const Duration(seconds: 100)),
        ),
        false,
      );
      expect(
        s.observe(
          fix(150),
          const Duration(seconds: 100),
          epoch.add(const Duration(seconds: 100)),
        ),
        false,
      );
      expect(observe(s, 120), true);
    },
  );
  test('long gaps reset stationary evidence and reacquire', () {
    final s = sampler();
    for (final t in [0, 30, 60, 90]) {
      observe(s, t);
    }
    observe(s, 300, latitude: 29);
    expect(s.motion, DutyMotion.acquiring);
    expect(s.intervalSeconds, 30);
  });
  test(
    'all HR cadences keep upload and retry bounds below half the stale threshold',
    () {
      for (final base in [15, 30, 60, 300]) {
        for (final stale in [base * 2, base * 4, 1800]) {
          final s = sampler(base: base, stale: stale)..lowBattery = true;
          expect(s.intervalSeconds, inInclusiveRange(base, stale ~/ 2));
          s.motion = DutyMotion.stationary;
          expect(s.intervalSeconds, inInclusiveRange(base, stale ~/ 2));
          s.attempted(Duration.zero);
          for (var i = 0; i < 10; i++) {
            s.failed();
          }
          expect(s.due(Duration(seconds: stale ~/ 2)), true);
          expect(s.due(Duration(seconds: base - 1)), false);
        }
      }
    },
  );
  test('backoff resets on delivery, and scheduling uses elapsed time', () {
    final s = sampler(stale: 240);
    s.attempted(Duration.zero);
    s.failed();
    s.failed();
    expect(s.due(const Duration(seconds: 60)), false);
    s.delivered();
    expect(s.due(const Duration(seconds: 30)), true);
    expect(s.due(const Duration(seconds: -1)), false);
  });
  test(
    'schedule polls and heartbeats keep contact inside HR stale threshold',
    () {
      for (final (stale, poll, contact) in [
        (120, 30, 65),
        (60, 17, 18),
        (30, 10, 0),
        (1800, 30, 1745),
      ]) {
        final s = sampler(base: 15, stale: stale);
        expect(s.pollSeconds, poll, reason: 'stale $stale');
        expect(s.contactSeconds, contact, reason: 'stale $stale');
        // Worst gap: a heartbeat due just after a poll waits one more poll;
        // plus HR's 15 s refresh and 5 s of network delay it stays in time.
        expect(
          s.contactSeconds + s.pollSeconds + 15 + 5,
          lessThanOrEqualTo(stale),
        );
      }
    },
  );
}
