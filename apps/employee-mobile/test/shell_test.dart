import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/main.dart';
import 'package:defence_garden_employee/app_router.dart' as app;
import 'package:defence_garden_employee/mobile_ui.dart';
import 'package:defence_garden_employee/providers.dart';
import 'package:defence_garden_employee/ui/components.dart';
import 'package:defence_garden_employee/dwr_screen.dart';
import 'package:defence_garden_employee/operation_vault.dart';
import 'package:defence_garden_employee/scope.dart';
import 'dart:io';
import 'support/fake_api.dart';

Future<void> loadFonts() async {
  for (final family in ['Manrope', 'NotoSansDevanagari']) {
    final loader = FontLoader(family);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
    }
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  final lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/Lucide.ttf'));
  await lucide.load();
}

Widget harness(FakeApi api) => ProviderScope(
  overrides: [
    apiProvider.overrideWithValue(api),
    operationRuntimeProvider.overrideWithValue(FakeRuntime(api)),
  ],
  child: const EmployeeApp(),
);

/// Pumps real time instead of pumpAndSettle: live timers (checked-in clock)
/// never settle by design.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> start(
  WidgetTester tester,
  FakeApi api, {
  Size size = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.reset);
  displaySettings.value = const DisplaySettings();
  appClock = () => DateTime(2026, 9, 22, 9, 30);
  app.router.go('/');
  await tester.pumpWidget(harness(api));
  await settle(tester);
}

Future<void> stop(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('bottom navigation stays visible on roots, details and forms', (
    tester,
  ) async {
    await start(tester, FakeApi());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(selectedTab(tester), 0);
    for (final (route, index, marker) in [
      ('/work/attendance', 1, 'Check in with photo'),
      ('/work/leave/apply', 1, 'Send for approval'),
      ('/work/tasks/task-1', 1, 'Inspect irrigation at Defence Garden'),
      ('/inbox/n-1', 2, 'What happened'),
      ('/me/settings', 3, 'Dark theme'),
      ('/me/records/payroll', 3, 'No published payslips yet'),
    ]) {
      app.router.go(route);
      await settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget, reason: route);
      expect(selectedTab(tester), index, reason: route);
      expect(find.text(marker), findsWidgets, reason: route);
      expect(
        find.text('Defence Garden'),
        findsWidgets,
        reason: 'site chip on $route',
      );
      expect(tester.takeException(), isNull, reason: route);
    }
    await stop(tester);
  });

  testWidgets('back returns through the branch stack and then to Home', (
    tester,
  ) async {
    await start(tester, FakeApi());
    app.router.go('/work/attendance');
    await settle(tester);
    expect(selectedTab(tester), 1);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('Daily work'), findsOneWidget);
    expect(selectedTab(tester), 1);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(selectedTab(tester), 0);
    expect(find.text('Needs attention'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('form action stays above the keyboard and navigation', (
    tester,
  ) async {
    await start(tester, FakeApi());
    app.router.go('/work/leave/apply');
    await settle(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await settle(tester);
    final nav = tester.getRect(find.byType(NavigationBar));
    expect(nav.bottom, lessThanOrEqualTo(844 - 320 + 0.5));
    // Constrained height: the action scrolls with the form instead of pinning.
    final submit = find.text('Send for approval');
    await tester.scrollUntilVisible(
      submit,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(submit);
    await settle(tester);
    expect(submit, findsOneWidget);
    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(nav.top + 0.5));
    expect(tester.takeException(), isNull);
    await stop(tester);
  });

  testWidgets('site switch replaces scoped values and resets other tabs', (
    tester,
  ) async {
    final api = FakeApi(
      sites: const [('site-dg', 'Defence Garden'), ('site-rg', 'River Green')],
    );
    await start(tester, api);
    expect(find.text('Choose site'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Choose site'));
    await settle(tester);
    await tester.tap(find.text('Defence Garden').last);
    await settle(tester);
    expect(find.text('Needs attention'), findsOneWidget);
    app.router.go('/work/tasks');
    await settle(tester);
    expect(find.text('Inspect irrigation at Defence Garden'), findsOneWidget);
    await tester.tap(find.byType(SiteChip).first);
    await settle(tester);
    await tester.tap(find.text('River Green').last);
    await settle(tester);
    expect(find.text('Inspect irrigation at Defence Garden'), findsNothing);
    expect(
      find.text('Daily work'),
      findsOneWidget,
      reason: 'current branch returned to its root',
    );
    app.router.go('/work/tasks');
    await settle(tester);
    expect(find.text('Inspect irrigation at River Green'), findsOneWidget);
    expect(find.text('Inspect irrigation at Defence Garden'), findsNothing);
    await stop(tester);
  });

  testWidgets('restricted role cannot reach hidden pages through shortcuts', (
    tester,
  ) async {
    await start(tester, FakeApi());
    app.router.go('/work');
    await settle(tester);
    expect(find.text('Users & module access'), findsNothing);
    expect(find.text('Approvals'), findsNothing);
    app.router.go('/work/access');
    await settle(tester);
    expect(
      find.text('You do not have access to this at the selected site.'),
      findsOneWidget,
    );
    await stop(tester);
  });

  testWidgets('manager sees the team section without losing daily actions', (
    tester,
  ) async {
    await start(tester, FakeApi(caps: FakeApi.managerCaps));
    app.router.go('/work');
    await settle(tester);
    expect(find.text('Daily work'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Users & module access'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Team'), findsWidgets);
    expect(find.text('Users & module access'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('profile update form sends photo-free changes for review', (
    tester,
  ) async {
    final api = FakeApi();
    await start(tester, api);
    app.router.go('/me/profile/request');
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Profile photo'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '+91 9111111111');
    await tester.scrollUntilVisible(
      find.text('O+'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('O+'));
    final note = find.descendant(
      of: find.ancestor(
        of: find.text('Note for HR'),
        matching: find.byType(LabeledField),
      ),
      matching: find.byType(TextFormField),
    );
    await tester.scrollUntilVisible(
      note,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(note, 'Widget verification only');
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Send to HR for review'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Send to HR for review'));
    await settle(tester);
    final write = api.writes.singleWhere(
      (w) => w['operation'] == 'request_profile',
    );
    expect(write['site'], 'site-dg');
    expect(write['input']['phone'], '+91 9111111111');
    expect(write['input']['expectedVersion'], 4);
    expect(write['input']['details'], {'bloodGroup': 'O+'});
    expect(write['input'].containsKey('photo'), isFalse);
    expect(find.text('Sent to HR for review'), findsWidgets);
    expect(find.text('My Profile'), findsWidgets, reason: 'form popped back');
    await stop(tester);
  });

  group('goldens', () {
    testWidgets('home light', (tester) async {
      await start(tester, FakeApi());
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_light.png'),
      );
      await stop(tester);
    });
    testWidgets('home checked in dark', (tester) async {
      await start(tester, FakeApi(checkedIn: true));
      await setDisplaySettings(dark: true);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_dark.png'),
      );
      await setDisplaySettings(dark: false);
      await stop(tester);
    });
    testWidgets('work light', (tester) async {
      await start(tester, FakeApi(caps: FakeApi.managerCaps));
      app.router.go('/work');
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/work_light.png'),
      );
      await stop(tester);
    });
    testWidgets('home narrow 320 has no overflow', (tester) async {
      await start(tester, FakeApi(), size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_narrow.png'),
      );
      await stop(tester);
    });
    testWidgets('work at 200% text scale in Hindi has no overflow', (
      tester,
    ) async {
      await start(tester, FakeApi(caps: FakeApi.managerCaps));
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await setDisplaySettings(language: 'hi');
      app.router.go('/work');
      await settle(tester);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/work_hindi_200.png'),
      );
      await setDisplaySettings(language: 'en');
      await stop(tester);
    });

    testWidgets('home landscape keeps navigation and content readable', (
      tester,
    ) async {
      await start(tester, FakeApi(), size: const Size(844, 390));
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_landscape.png'),
      );
      await stop(tester);
    });
    testWidgets('DWR agent chat light', (tester) async {
      await start(tester, FakeApi());
      app.router.go('/work/daily-report');
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Pump room ka valve replace kiya'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dwr_chat_light.png'),
      );
      await stop(tester);
    });
    testWidgets('DWR group chat dark', (tester) async {
      await start(tester, FakeApi());
      await setDisplaySettings(dark: true);
      app.router.go('/work/daily-report/chat/group-1');
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Ravi Kumar'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dwr_group_dark.png'),
      );
      await setDisplaySettings(dark: false);
      await stop(tester);
    });
    testWidgets('daily report editor light', (tester) async {
      final vault = (await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('dwr-golden-');
        addTearDown(() => root.delete(recursive: true));
        return OperationVault.open('org', 'actor', root: root);
      }))!;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.reset);
      displaySettings.value = const DisplaySettings();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: employeeTheme(Brightness.light),
            home: DwrEditor(
              scope: const SiteScope('org', 'actor', 7, 'site-one'),
              report: {
                'isSelf': true,
                'status': 'draft',
                'version': 0,
                'work_date': '2026-09-22',
                'content': blankDwr(),
                'attachments': [],
              },
              data: {
                'site': {'name': 'Defence Garden'},
                'settings': {'offline_drafts': true},
                'voice': {'configured': true},
              },
              caps: const [
                'my_dwr.view',
                'my_dwr.create',
                'my_dwr.edit',
                'my_dwr.submit',
              ],
              vault: vault,
              offline: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dwr_editor_light.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
