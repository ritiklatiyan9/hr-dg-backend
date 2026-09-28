import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/attendance.dart';
import 'package:defence_garden_employee/attendance_location.dart';
import 'package:defence_garden_employee/operation_runtime.dart'
    show attendanceDutyExpired, nextAttendanceSequence;

void main() {
  final now = DateTime.utc(2026, 9, 26, 10);
  final rules = {'maxAccuracyM': 100, 'freshnessSeconds': 60};
  final fence = {
    'type': 'Polygon',
    'coordinates': [
      [
        [77.19, 28.59],
        [77.21, 28.59],
        [77.21, 28.61],
        [77.19, 28.61],
        [77.19, 28.59],
      ],
    ],
  };
  final fix = {
    'latitude': 28.6,
    'longitude': 77.2,
    'accuracyM': 10,
    'observedAt': now.toIso8601String(),
    'mocked': false,
  };
  test(
    'cached GPS needs fresh, accurate, non-mocked evidence; boundary prompts conservatively',
    () {
      expect(attendanceInside(fence, fix, rules, now: now), true);
      for (final p in [
        null,
        {...fix, 'longitude': 78},
        {...fix, 'longitude': 77.19001},
        {...fix, 'accuracyM': 101},
        {...fix, 'mocked': true},
        {
          ...fix,
          'observedAt': now
              .subtract(const Duration(seconds: 16))
              .toIso8601String(),
        },
      ]) {
        expect(attendanceInside(fence, p, rules, now: now), false);
      }
      expect(attendanceInside(null, fix, rules, now: now), false);
    },
  );
  test(
    'pending OUT keeps duty open but prevents duplicate OUT; rejected IN can be retried',
    () {
      expect(
        const AttendanceStatus(
          open: {'id': 'd'},
          events: [
            {'kind': 'IN', 'status': 'accepted'},
            {'kind': 'OUT', 'status': 'pending_verification'},
          ],
        ).awaitingOut,
        true,
      );
      expect(
        const AttendanceStatus(
          open: {'id': 'd'},
          events: [
            {'kind': 'IN', 'status': 'rejected'},
          ],
        ).checkedIn,
        false,
      );
      expect(
        const AttendanceStatus(
          open: {'id': 'd'},
          events: [
            {'kind': 'IN', 'status': 'accepted'},
            {'kind': 'OUT', 'status': 'rejected'},
          ],
        ).awaitingOut,
        false,
      );
    },
  );
  test(
    'failed local OUT reuses its uncommitted sequence; server rejections and pending receipts consume theirs',
    () {
      const session = {'id': 'd', 'last_sequence': 1, 'max_sequence': 1};
      final failed = {
        'state': 'rejected',
        'payload': {'dutyId': 'd', 'sequence': 2},
      };
      expect(nextAttendanceSequence('d', session, [failed]), 2);
      expect(
        nextAttendanceSequence('d', session, [
          {...failed, 'serverId': 'event-2'},
        ]),
        3,
      );
      expect(
        nextAttendanceSequence('d', session, [
          {...failed, 'state': 'pending_sync'},
        ]),
        3,
      );
      expect(
        nextAttendanceSequence('d', {...session, 'max_sequence': 4}, [failed]),
        5,
      );
    },
  );
  test(
    'an expired open duty belongs to history, including overnight shifts',
    () {
      final opened = DateTime.utc(2026, 9, 27, 18);
      final session = {'opened_at': opened.toIso8601String()};
      expect(
        attendanceDutyExpired(session, {
          'maxSessionHours': 18,
        }, now: opened.add(const Duration(hours: 17))),
        false,
      );
      expect(
        attendanceDutyExpired(session, {
          'maxSessionHours': 18,
        }, now: opened.add(const Duration(hours: 18))),
        true,
      );
      expect(
        attendanceDutyExpired(
          {
            ...session,
            'expires_at': opened
                .add(const Duration(hours: 24))
                .toIso8601String(),
          },
          {'maxSessionHours': 18},
          now: opened.add(const Duration(hours: 19)),
        ),
        false,
      );
    },
  );
  testWidgets(
    'OUT reason dialog validates input and makes approval requirement explicit',
    (tester) async {
      String? reason;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  reason = await requestAttendanceOutReason(context);
                },
                child: const Text('OUT'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OUT'));
      await tester.pumpAndSettle();
      expect(find.textContaining('counts only after'), findsOneWidget);
      await tester.tap(find.text('Submit for approval'));
      await tester.pumpAndSettle();
      expect(find.text('Enter at least 8 characters'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Returning from client visit',
      );
      await tester.tap(find.text('Submit for approval'));
      await tester.pumpAndSettle();
      expect(reason, 'Returning from client visit');
    },
  );
}
