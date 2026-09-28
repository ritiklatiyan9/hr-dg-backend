import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

enum DutyMotion { acquiring, moving, stationary }

/// Changes cadence, never coordinates. Monotonic elapsed time controls uploads;
/// GPS timestamps are checked against a server-derived clock before use.
class DutySampling {
  DutySampling({
    required this.baseSeconds,
    required this.staleSeconds,
    required this.maxAccuracyM,
    required this.freshnessSeconds,
  });
  final int baseSeconds, staleSeconds, freshnessSeconds;
  final double maxAccuracyM;
  DutyMotion motion = DutyMotion.acquiring;
  bool lowBattery = false;
  Position? _anchor, _previous;
  Duration? _quietSince, _lastAttempt, _lastEvidence;
  int _quietFixes = 0, _movementFixes = 0, _failures = 0;
  String? rejectedReason;

  // Reserve half of HR's stale threshold for delivery and schedule jitter.
  int get heartbeatSeconds => math.max(baseSeconds, staleSeconds ~/ 2);

  /// A still phone gets no GPS callbacks, so contact is kept by the schedule
  /// poll plus a heartbeat. The worst gap between two contacts is
  /// `staleSeconds - 25`: room for HR's 15 s refresh and network delay, so a
  /// connected phone never looks lost.
  int get pollSeconds => ((staleSeconds - 25) ~/ 2).clamp(10, 30);
  int get contactSeconds => math.max(0, staleSeconds - 25 - pollSeconds);
  int get intervalSeconds {
    final multiplier = motion == DutyMotion.stationary
        ? 3
        : lowBattery
        ? 2
        : 1;
    return math.min(heartbeatSeconds, baseSeconds * multiplier);
  }

  String get label => motion == DutyMotion.stationary
      ? 'Stationary · battery saving'
      : lowBattery
      ? 'Low battery · reduced frequency'
      : motion == DutyMotion.moving
      ? 'Moving · precise tracking'
      : 'Acquiring movement';

  bool observe(Position p, Duration elapsed, DateTime serverNow) {
    rejectedReason = null;
    final age = serverNow.difference(p.timestamp).inMilliseconds;
    if (p.isMocked ||
        !p.latitude.isFinite ||
        !p.longitude.isFinite ||
        p.latitude.abs() > 90 ||
        p.longitude.abs() > 180 ||
        !p.accuracy.isFinite ||
        p.accuracy < 0 ||
        p.accuracy > maxAccuracyM ||
        age < -5000 ||
        age > freshnessSeconds * 1000) {
      rejectedReason = 'Waiting for a fresh, precise GPS reading';
      return false;
    }
    if (_previous != null && !p.timestamp.isAfter(_previous!.timestamp)) {
      return false;
    }
    // A long gap gives no evidence of stillness. Start acquisition again.
    if (_lastEvidence != null &&
        elapsed - _lastEvidence! >
            Duration(seconds: math.max(120, heartbeatSeconds * 2))) {
      _anchor = null;
      _previous = null;
      _quietSince = null;
      _quietFixes = 0;
      _movementFixes = 0;
      motion = DutyMotion.acquiring;
    }
    if (_previous != null) {
      final seconds =
          p.timestamp.difference(_previous!.timestamp).inMilliseconds / 1000;
      final distance = Geolocator.distanceBetween(
        _previous!.latitude,
        _previous!.longitude,
        p.latitude,
        p.longitude,
      );
      // Reject an isolated teleport, accounting for both accuracy radii.
      if (seconds > 0 &&
          seconds < 120 &&
          (distance - p.accuracy - _previous!.accuracy) / seconds > 100) {
        rejectedReason = 'GPS jump ignored; waiting for a consistent reading';
        return false;
      }
    }
    _lastEvidence = elapsed;
    _previous = p;
    _anchor ??= p;
    _quietSince ??= elapsed;
    final displacement = Geolocator.distanceBetween(
      _anchor!.latitude,
      _anchor!.longitude,
      p.latitude,
      p.longitude,
    );
    final uncertainty = math.max(
      12.0,
      math.sqrt(
            p.accuracy * p.accuracy + _anchor!.accuracy * _anchor!.accuracy,
          ) *
          1.5,
    );
    final confidentSpeed =
        p.speed.isFinite &&
        p.speedAccuracy.isFinite &&
        p.speedAccuracy > 0 &&
        p.speedAccuracy <= 0.7 &&
        p.speed - p.speedAccuracy >= 0.9;
    if (displacement > uncertainty || confidentSpeed) {
      _movementFixes++;
      _quietFixes = 0;
      _quietSince = elapsed;
      if (_movementFixes >= 2 || confidentSpeed) {
        motion = DutyMotion.moving;
        _anchor = p;
        _movementFixes = 0;
      }
    } else {
      _movementFixes = 0;
      _quietFixes++;
      if (_quietFixes >= 3 &&
          elapsed - _quietSince! >= const Duration(seconds: 90)) {
        motion = DutyMotion.stationary;
      }
    }
    return true;
  }

  bool due(Duration elapsed) {
    final retry = math.min(
      heartbeatSeconds,
      baseSeconds * (1 << math.min(_failures, 3)),
    );
    final seconds = math.max(intervalSeconds, retry);
    return _lastAttempt == null ||
        elapsed - _lastAttempt! >= Duration(seconds: seconds);
  }

  void attempted(Duration elapsed) => _lastAttempt = elapsed;
  void delivered() => _failures = 0;
  void failed() => _failures = math.min(3, _failures + 1);
}
