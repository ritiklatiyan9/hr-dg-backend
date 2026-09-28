import 'dart:math' as math;

/// Used only to choose the reason prompt. The API rechecks in PostGIS.
bool attendanceFixFresh(Map? fix, Map? rules, {DateTime? now}) {
  final accuracy = fix?['accuracyM'];
  return fix != null &&
      fix['mocked'] != true &&
      attendanceFixRecent(fix, rules, now: now) &&
      accuracy is num &&
      accuracy.isFinite &&
      accuracy >= 0 &&
      accuracy <= ((rules?['maxAccuracyM'] as num?) ?? 5);
}

bool attendanceFixRecent(Map? fix, Map? rules, {DateTime? now}) {
  final observed = DateTime.tryParse('${fix?['observedAt']}');
  return observed != null &&
      (now ?? DateTime.now()).difference(observed).inMilliseconds.abs() <=
          math.min((rules?['freshnessSeconds'] as num?) ?? 5, 15) * 1000;
}

bool attendanceInside(Map? fence, Map? fix, Map? rules, {DateTime? now}) {
  if (!attendanceFixFresh(fix, rules, now: now) ||
      fence?['type'] != 'Polygon') {
    return false;
  }
  final rings = fence?['coordinates'] as List?;
  if (rings == null || rings.length != 1) return false;
  final ring = rings.first as List;
  if (ring.length < 4) return false;
  final scale = math.cos((fix!['latitude'] as num) * math.pi / 180);
  var inside = false;
  for (var i = 1; i < ring.length; i++) {
    final a = ring[i - 1] as List, b = ring[i] as List;
    if (((a[0] as num) - (b[0] as num)).abs() > 180) return false;
    final ax = ((a[0] as num) - fix['longitude']) * 111320 * scale;
    final ay = ((a[1] as num) - fix['latitude']) * 110574;
    final bx = ((b[0] as num) - fix['longitude']) * 111320 * scale;
    final by = ((b[1] as num) - fix['latitude']) * 110574;
    final dx = bx - ax, dy = by - ay;
    final length = dx * dx + dy * dy;
    final t = (-(ax * dx + ay * dy) / (length == 0 ? 1 : length)).clamp(0, 1);
    if (math.sqrt(math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2)) <=
        (fix['accuracyM'] as num) + 3) {
      return false;
    }
    if ((ay > 0) != (by > 0) && (bx - ax) * -ay / (by - ay) + ax > 0) {
      inside = !inside;
    }
  }
  return inside;
}
