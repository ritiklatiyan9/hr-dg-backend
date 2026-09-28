import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:defence_garden_employee/api.dart';
import 'package:defence_garden_employee/scope.dart';
import 'package:defence_garden_employee/operation_runtime.dart';
import 'package:defence_garden_employee/attendance.dart';
import 'package:defence_garden_employee/outbox.dart';
import 'package:defence_garden_employee/tasks.dart';
import 'package:defence_garden_employee/providers.dart';
import 'package:defence_garden_employee/mobile_ui.dart';
import 'package:defence_garden_employee/graphql/operations.graphql.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'durable offline operation survives native process relaunch and syncs original site',
    (tester) async {
      const stage = String.fromEnvironment(
        'OUTBOX_STAGE',
        defaultValue: 'capture',
      );
      final api = HrApi();
      final runtime = OperationRuntime(api);
      SiteScope? resumed;
      if (stage == 'capture') {
        await api.login(
          'employee@example.test',
          const String.fromEnvironment('TEST_PASSWORD'),
        );
        final b = (await api.bootstrap()).bootstrap;
        final scope = SiteScope(
          b.organization.id,
          b.actor.id,
          b.actor.permissionVersion,
          '20000000-0000-4000-8000-000000000001',
        );
        final data = Json.from(
          (await api.scopedRead(
                scope,
                documentNodeQueryOperations,
              ))['operations']
              as Map,
        );
        await runtime.connect(
          scope,
          data,
          (await api.capabilities(scope)).scope.capabilities,
        );
        expect(runtime.canSaveOffline, true);
        final tasks = data['tasks'] as List;
        expect(tasks, isNotEmpty);
        // Enqueue without invoking sync, then the driver terminates the process.
        await runtime.enqueue(scope, 'comment', {
          'clientId': const Uuid().v4(),
          'taskId': tasks.first['id'],
          'body': 'Synthetic encrypted relaunch verification',
        });
        expect(runtime.queue.any((e) => e['state'] == 'saved_locally'), true);
        await runtime.close();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Saved locally • encrypted\nOriginal site: Defence Garden\nReady for process relaunch',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        );
      } else {
        expect(await api.restore(), true);
        expect(await runtime.restoreOffline(), true);
        final queued = runtime.queue
            .where(
              (e) =>
                  e['payload']['body'] ==
                  'Synthetic encrypted relaunch verification',
            )
            .toList();
        expect(queued, isNotEmpty);
        final original = queued.last;
        expect(original['siteId'], '20000000-0000-4000-8000-000000000001');
        await runtime.sync(force: true);
        expect(
          runtime.queue.firstWhere((e) => e['id'] == original['id'])['state'],
          'accepted',
        );
        final b = (await api.bootstrap()).bootstrap;
        final scope = SiteScope(
          b.organization.id,
          b.actor.id,
          b.actor.permissionVersion,
          original['siteId'] as String,
        );
        resumed = scope;
        final snapshot =
            (await api.scopedRead(
                  scope,
                  documentNodeQueryOperations,
                ))['operations']
                as Map;
        expect(
          (snapshot['comments'] as List)
              .where((c) => c['client_id'] == original['id'])
              .length,
          1,
        );
        await runtime.sync(force: true);
        final again =
            (await api.scopedRead(
                  scope,
                  documentNodeQueryOperations,
                ))['operations']
                as Map;
        expect(
          (again['comments'] as List)
              .where((c) => c['client_id'] == original['id'])
              .length,
          1,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiProvider.overrideWithValue(api),
              operationRuntimeProvider.overrideWithValue(runtime),
            ],
            child: MaterialApp(
              theme: employeeTheme(Brightness.light),
              home: AttendancePage(scope: scope),
            ),
          ),
        );
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          if (find.text('History').evaluate().isNotEmpty) break;
        }
        expect(find.text('History'), findsOneWidget);
      }
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('flutter-offline-$stage');
      if (stage != 'capture') {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiProvider.overrideWithValue(api),
              operationRuntimeProvider.overrideWithValue(runtime),
            ],
            child: MaterialApp(
              theme: employeeTheme(Brightness.light),
              home: TasksPage(scope: resumed!),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot('flutter-tasks');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiProvider.overrideWithValue(api),
              operationRuntimeProvider.overrideWithValue(runtime),
            ],
            child: MaterialApp(
              theme: employeeTheme(Brightness.light),
              home: const OutboxPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot('flutter-outbox');
        await runtime.close();
      }
    },
  );
}
