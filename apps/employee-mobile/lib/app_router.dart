import 'ui/icons.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'access.dart';
import 'analytics_screen.dart';
import 'approvals.dart';
import 'attendance.dart';
import 'dwr_chat.dart';
import 'dwr_screen.dart';
import 'home_tab.dart';
import 'hr_services.dart';
import 'inbox.dart';
import 'leave.dart';
import 'main.dart';
import 'me_tab.dart';
import 'mobile_ui.dart';
import 'outbox.dart';
import 'push_notifications.dart';
import 'providers.dart';
import 'scope.dart';
import 'tasks.dart';
import 'team.dart';
import 'ui/components.dart';
import 'work_tab.dart';
import 'workspace.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final branchKeys = [
  GlobalKey<NavigatorState>(debugLabel: 'home'),
  GlobalKey<NavigatorState>(debugLabel: 'work'),
  GlobalKey<NavigatorState>(debugLabel: 'inbox'),
  GlobalKey<NavigatorState>(debugLabel: 'me'),
];

const tabRoots = ['/home', '/work', '/inbox', '/me'];

/// Canonical destination for an HR record kind. Work owns requests; Me owns
/// personal records. Team approvals open the same detail page.
String recordRoute(String kind, [String? id]) {
  final branch =
      const {
        'expense': '/work',
        'helpdesk': '/work',
        'grievance': '/work',
      }[kind] ??
      '/me';
  return '$branch/records/$kind${id == null ? '' : '/$id'}';
}

/// Route for an inbox notification. Untrusted ids are only used as selectors;
/// every target page re-checks authorization on load.
String routeForNotification(Map item) {
  final type = '${item['event_type']}',
      module = '${item['module']}',
      id = item['entity_id']?.toString();
  final parts = type.split('.');
  // HR records use hr.<kind>.<status>.v<version>.
  final kind = parts.first == 'hr' && parts.length > 1 ? parts[1] : parts.first;
  if (const [
    'expense',
    'asset',
    'helpdesk',
    'grievance',
    'document',
    'policy',
    'announcement',
    'lifecycle',
  ].contains(kind)) {
    return recordRoute(kind, id);
  }
  if (kind == 'payroll' || module == 'my_payroll') {
    return recordRoute('payroll', id);
  }
  if (kind == 'task') return id == null ? '/work/tasks' : '/work/tasks/$id';
  if (kind == 'leave') return '/work/leave';
  if (kind == 'visit') return '/work/field-duty';
  if (type == 'dwr.group.added' && id != null) {
    return '/work/daily-report/chat/$id';
  }
  if (module.contains('dwr') || kind == 'dwr') {
    return module == 'dwr_review'
        ? '/work/daily-report?queue=team'
        : '/work/daily-report';
  }
  return '/work/attendance';
}

Widget _scoped(Widget Function(SiteScope scope) builder) =>
    ScopedRoute(builder: builder);

List<RouteBase> _sharedRoutes() => [
  GoRoute(
    path: 'attachment/:id',
    builder: (c, s) => _scoped(
      (scope) => AttachmentViewerPage(
        scope: scope,
        id: s.pathParameters['id']!,
        declaredType: s.uri.queryParameters['type'],
        title: s.uri.queryParameters['title'],
        bytes: s.extra is Uint8List ? s.extra as Uint8List : null,
      ),
    ),
  ),
];

List<RouteBase> _recordRoutes() => [
  GoRoute(
    path: 'records/:kind',
    builder: (c, s) => _scoped(
      (scope) => RecordsPage(scope: scope, kind: s.pathParameters['kind']!),
    ),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (c, s) => _scoped(
          (scope) => RecordEditorPage(
            scope: scope,
            kind: s.pathParameters['kind']!,
            args: s.extra is RecordEditorArgs
                ? s.extra as RecordEditorArgs
                : null,
          ),
        ),
      ),
      GoRoute(
        path: ':id',
        builder: (c, s) => _scoped(
          (scope) => RecordDetailPage(
            scope: scope,
            kind: s.pathParameters['kind']!,
            id: s.pathParameters['id']!,
          ),
        ),
      ),
    ],
  ),
];

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SessionGate()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: branchKeys[0],
          routes: [
            GoRoute(
              path: '/home',
              builder: (c, s) => const HomeTab(),
              routes: [
                GoRoute(
                  path: 'activity',
                  builder: (c, s) =>
                      _scoped((scope) => ActivityPage(scope: scope)),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: branchKeys[1],
          routes: [
            GoRoute(
              path: '/work',
              builder: (c, s) => const WorkTab(),
              routes: [
                GoRoute(
                  path: 'attendance',
                  builder: (c, s) =>
                      _scoped((scope) => AttendancePage(scope: scope)),
                  routes: [
                    GoRoute(
                      path: 'fix',
                      builder: (c, s) => _scoped(
                        (scope) => FixAttendancePage(
                          scope: scope,
                          dutyId: s.uri.queryParameters['duty'],
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'field-duty',
                  builder: (c, s) =>
                      _scoped((scope) => FieldDutyPage(scope: scope)),
                ),
                GoRoute(
                  path: 'daily-report',
                  // Default: the personal DWR agent chat for the whole month.
                  // Local encrypted drafts stay reachable when bootstrap fails.
                  builder: (c, s) => Consumer(
                    builder: (context, ref, _) {
                      final scope = ref.watch(currentScopeProvider);
                      if (scope == null) {
                        return const DailyReportPage(scope: null);
                      }
                      return KeyedSubtree(
                        key: ValueKey(scope),
                        child: s.uri.queryParameters['queue'] == 'team'
                            ? DailyReportPage(scope: scope, queue: true)
                            : DwrHomePage(scope: scope),
                      );
                    },
                  ),
                  routes: [
                    GoRoute(
                      path: 'reports',
                      builder: (c, s) =>
                          _scoped((scope) => DailyReportPage(scope: scope)),
                    ),
                    GoRoute(
                      path: 'chats',
                      builder: (c, s) =>
                          _scoped((scope) => DwrChatsPage(scope: scope)),
                    ),
                    GoRoute(
                      path: 'new-group',
                      builder: (c, s) =>
                          _scoped((scope) => DwrNewGroupPage(scope: scope)),
                    ),
                    GoRoute(
                      path: 'chat/:groupId',
                      builder: (c, s) => _scoped(
                        (scope) => DwrChatPage(
                          scope: scope,
                          groupId: s.pathParameters['groupId'] == 'me'
                              ? null
                              : s.pathParameters['groupId'],
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'info',
                          builder: (c, s) => _scoped(
                            (scope) => DwrGroupInfoPage(
                              scope: scope,
                              groupId: s.pathParameters['groupId']!,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'edit',
                      builder: (c, s) => _scoped(
                        (scope) => DwrEditorPage(
                          scope: scope,
                          args: s.extra is DwrEditorArgs
                              ? s.extra as DwrEditorArgs
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'tasks',
                  builder: (c, s) =>
                      _scoped((scope) => TasksPage(scope: scope)),
                  routes: [
                    GoRoute(
                      path: 'assign',
                      builder: (c, s) =>
                          _scoped((scope) => AssignTaskPage(scope: scope)),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (c, s) => _scoped(
                        (scope) => TaskDetailPage(
                          scope: scope,
                          id: s.pathParameters['id']!,
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'leave',
                  builder: (c, s) =>
                      _scoped((scope) => LeavePage(scope: scope)),
                  routes: [
                    GoRoute(
                      path: 'apply',
                      builder: (c, s) =>
                          _scoped((scope) => ApplyLeavePage(scope: scope)),
                    ),
                  ],
                ),
                ..._recordRoutes(),
                GoRoute(
                  path: 'team',
                  builder: (c, s) =>
                      _scoped((scope) => PeoplePage(scope: scope)),
                  routes: [
                    GoRoute(
                      path: 'attendance',
                      builder: (c, s) =>
                          _scoped((scope) => TeamAttendancePage(scope: scope)),
                    ),
                    GoRoute(
                      path: 'person',
                      builder: (c, s) => _scoped(
                        (scope) =>
                            PersonDetailPage(scope: scope, person: s.extra),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'approvals',
                  builder: (c, s) =>
                      _scoped((scope) => ApprovalsPage(scope: scope)),
                ),
                GoRoute(
                  path: 'access',
                  builder: (c, s) =>
                      _scoped((scope) => AccessUsersPage(scope: scope)),
                  routes: [
                    GoRoute(
                      path: ':userId',
                      builder: (c, s) => _scoped(
                        (scope) => AccessEditorPage(
                          scope: scope,
                          userId: s.pathParameters['userId']!,
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'insights',
                  builder: (c, s) =>
                      _scoped((scope) => AnalyticsScreen(scope: scope)),
                ),
                ..._sharedRoutes(),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: branchKeys[2],
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (c, s) => const InboxTab(),
              routes: [
                ..._sharedRoutes(),
                GoRoute(
                  path: ':id',
                  builder: (c, s) => _scoped(
                    (scope) => MessageDetailPage(
                      scope: scope,
                      id: s.pathParameters['id']!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: branchKeys[3],
          routes: [
            GoRoute(
              path: '/me',
              builder: (c, s) => const MeTab(),
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (c, s) =>
                      _scoped((scope) => ProfilePage(scope: scope)),
                  routes: [
                    GoRoute(
                      path: 'request',
                      builder: (c, s) =>
                          _scoped((scope) => ProfileRequestPage(scope: scope)),
                    ),
                  ],
                ),
                ..._recordRoutes(),
                GoRoute(
                  path: 'settings',
                  builder: (c, s) => const SettingsPage(),
                ),
                GoRoute(path: 'outbox', builder: (c, s) => const OutboxPage()),
                ..._sharedRoutes(),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Builds a page for the currently selected site. A page is keyed by its
/// scope, so a site or permission change discards old state and values.
class ScopedRoute extends ConsumerWidget {
  const ScopedRoute({super.key, required this.builder});
  final Widget Function(SiteScope scope) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(currentScopeProvider);
    if (scope == null) return const ChooseSitePage();
    return KeyedSubtree(key: ValueKey(scope), child: builder(scope));
  }
}

class ChooseSitePage extends ConsumerWidget {
  const ChooseSitePage({super.key, this.title});
  final String? title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(bootstrapProvider).value?.bootstrap;
    return PageScaffold(
      title: title ?? tr('Choose a site', 'साइट चुनें'),
      showSite: false,
      body: ListView(
        padding: Space.page,
        children: [
          EmptyState(
            title: tr('Choose your work site', 'अपनी साइट चुनें'),
            message: b == null || b.sites.isEmpty
                ? tr(
                    'No active memberships. Contact your administrator.',
                    'कोई सक्रिय सदस्यता नहीं। व्यवस्थापक से संपर्क करें।',
                  )
                : tr(
                    'Attendance, reports and requests are recorded at the site you select.',
                    'उपस्थिति, रिपोर्ट और अनुरोध चयनित साइट पर दर्ज होते हैं।',
                  ),
            illustration: TinyKind.site,
            action: b == null || b.sites.isEmpty
                ? null
                : ActionButton(
                    tr('Choose site', 'साइट चुनें'),
                    icon: AppIcons.mapPin,
                    expanded: false,
                    onPressed: () => showSitePicker(context, ref),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Non-home tab roots return to Home on platform Back instead of exiting.
class TabRoot extends StatelessWidget {
  const TabRoot({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      StatefulNavigationShell.of(context).goBranch(0);
    },
    child: child,
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver
    implements AppShellActions {
  Timer? accessTimer;
  StreamSubscription<String>? invalidations;
  bool refreshing = false;
  Object? connectionError;

  /// Workspace epoch each branch was last shown with; a stale branch is reset
  /// to its root the next time it is selected.
  final branchEpoch = List<int>.filled(4, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startTimer();
    final push = PushNotifications.instance
      ..onOpen = openPush
      ..onForeground = showPush;
    // Every opened site registers this device; failures leave the inbox as is.
    ref.listenManual(currentScopeProvider, (_, scope) {
      if (scope != null) {
        push.enable(ref.read(apiProvider), scope).ignore();
      }
    }, fireImmediately: true);
    invalidations = ref.read(apiProvider).invalidations.stream.listen((
      code,
    ) async {
      if (!mounted) return;
      await ref.read(workspaceActionsProvider).clearScoped();
      ref.invalidate(bootstrapProvider);
      if (code == 'UNAUTHENTICATED' || code == 'MFA_REQUIRED') {
        ref.read(workspaceProvider.notifier).reset();
        if (mounted) context.go('/login');
      }
    });
  }

  /// A tapped notification: switch to its site when needed, then open the
  /// related page, which re-checks access on load.
  Future<void> openPush(Map<String, dynamic> data) async {
    if (!mounted) return;
    final site = '${data['siteId']}';
    final b = ref.read(bootstrapProvider).value?.bootstrap;
    if (b == null || !b.sites.any((s) => s.id == site)) return;
    if (site != ref.read(workspaceProvider).siteId) {
      await changeSite(site);
      if (!mounted || ref.read(workspaceProvider).siteId != site) return;
    }
    context.go(
      routeForNotification({
        'event_type': data['eventType'],
        'module': data['module'],
        'entity_id': data['entityId'],
      }),
    );
  }

  void showPush(String title, String body, Map<String, dynamic> data) {
    if (!mounted) return;
    final scope = ref.read(currentScopeProvider);
    if (scope != null && data['siteId'] == scope.siteId) {
      ref.read(operationsProvider(scope).notifier).load(silent: true).ignore();
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        action: SnackBarAction(
          label: tr('Open', 'खोलें'),
          onPressed: () => openPush(data),
        ),
      ),
    );
  }

  void startTimer() {
    accessTimer?.cancel();
    accessTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => checkAccess(),
    );
  }

  @override
  void dispose() {
    accessTimer?.cancel();
    invalidations?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(bootstrapProvider);
      checkAccess();
      startTimer();
    } else if (state == AppLifecycleState.paused) {
      accessTimer?.cancel();
    }
  }

  Future<void> checkAccess() async {
    if (refreshing || !mounted) return;
    refreshing = true;
    try {
      final next = (await ref.read(apiProvider).bootstrap()).bootstrap;
      final old = ref.read(bootstrapProvider).value?.bootstrap;
      if (old != null && old.actor.id != next.actor.id) {
        await ref.read(workspaceActionsProvider).clearScoped();
        ref.read(workspaceProvider.notifier).reset();
        ref.invalidate(bootstrapProvider);
      } else if (old != null &&
          old.actor.permissionVersion != next.actor.permissionVersion) {
        await ref.read(workspaceActionsProvider).clearScoped();
        ref.invalidate(bootstrapProvider);
      }
      if (mounted && connectionError != null) {
        setState(() => connectionError = null);
      }
    } catch (e) {
      if (mounted) setState(() => connectionError = e);
    } finally {
      refreshing = false;
    }
  }

  /// Returns true when it is safe to leave the current work behind.
  Future<bool> guardUnsaved({required String action}) async {
    final unsaved = ref.read(unsavedWorkProvider);
    if (!unsaved.any) return true;
    if (!mounted) return false;
    return confirmDialog(
      context,
      title: tr('Discard unsaved changes?', 'असहेजे बदलाव हटाएँ?'),
      message: tr(
        '${unsaved.label ?? tr('A form', 'एक फ़ॉर्म')} has changes that are not saved yet.',
        '${unsaved.label ?? 'एक फ़ॉर्म'} में असहेजे बदलाव हैं।',
      ),
      confirmLabel: tr('Discard', 'हटाएँ'),
      cancelLabel: tr('Keep editing', 'संपादन जारी रखें'),
      destructive: true,
    );
  }

  @override
  Future<void> changeSite(String siteId) async {
    final b = ref.read(bootstrapProvider).value?.bootstrap;
    if (b == null) return;
    if (siteId == ref.read(workspaceProvider).siteId) return;
    if (!await guardUnsaved(action: tr('switch sites', 'साइट बदलने'))) return;
    if (!mounted) return;
    await ref
        .read(workspaceActionsProvider)
        .selectSite(siteId, actorId: b.actor.id);
    if (!mounted) return;
    final epoch = ref.read(workspaceProvider).epoch;
    for (var i = 0; i < branchEpoch.length; i++) {
      branchEpoch[i] = i == widget.shell.currentIndex ? epoch : -1;
    }
    context.go(tabRoots[widget.shell.currentIndex]);
    HapticFeedback.selectionClick();
  }

  @override
  Future<void> signOut() async {
    if (!await guardUnsaved(action: tr('sign out', 'साइन आउट करने'))) return;
    final runtime = ref.read(operationRuntimeProvider);
    final api = ref.read(apiProvider);
    final hasDwrDrafts = await api.hasLocalDwrDrafts();
    if (!mounted) return;
    if (hasDwrDrafts ||
        runtime.queue.any(
          (e) => !['accepted', 'rejected'].contains(e['state']),
        )) {
      final confirmed = await confirmDialog(
        context,
        title: tr('Delete local pending work?', 'स्थानीय लंबित कार्य मिटाएँ?'),
        message: tr(
          'Signing out deletes local drafts, unsynchronized records and their encryption key on this device. Save daily report drafts online and synchronize pending work first to keep them.',
          'साइन आउट से स्थानीय ड्राफ़्ट, असिंक रिकॉर्ड और एन्क्रिप्शन कुंजी मिटती है। पहले रिपोर्ट ऑनलाइन सहेजें और लंबित कार्य सिंक करें।',
        ),
        confirmLabel: tr('Sign out and delete', 'साइन आउट करें और मिटाएँ'),
        cancelLabel: tr('Keep working', 'काम जारी रखें'),
        destructive: true,
      );
      if (!confirmed) return;
    }
    PushNotifications.instance.forget();
    try {
      await api.logout();
    } finally {
      ref.invalidate(bootstrapProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(capabilityProvider);
      ref.invalidate(requestsProvider);
      ref.read(workspaceProvider.notifier).reset();
      if (mounted) context.go('/login');
    }
  }

  Future<void> selectTab(int index) async {
    final shell = widget.shell;
    if (index != shell.currentIndex) {
      final epoch = ref.read(workspaceProvider).epoch;
      final stale = branchEpoch[index] != epoch;
      branchEpoch[index] = epoch;
      shell.goBranch(index, initialLocation: stale);
      HapticFeedback.selectionClick();
      return;
    }
    // Reselecting the active tab returns to its root, respecting unsaved work.
    final nav = branchKeys[index].currentState;
    if (nav == null || !nav.canPop()) return;
    if (!await guardUnsaved(action: tr('leave this page', 'यह पृष्ठ छोड़ने'))) {
      return;
    }
    shell.goBranch(index, initialLocation: true);
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(bootstrapProvider);
    ref.listen(bootstrapProvider, (prev, next) {
      final b = next.value?.bootstrap;
      if (b != null) {
        ref
            .read(workspaceActionsProvider)
            .restoreSelection(b.actor.id, b.sites.map((s) => s.id).toList());
      }
      // Track the epoch so freshly built branches are not reset needlessly.
      final epoch = ref.read(workspaceProvider).epoch;
      for (var i = 0; i < branchEpoch.length; i++) {
        if (branchEpoch[i] == 0) branchEpoch[i] = epoch;
      }
    });
    final runtime = ref.watch(operationRuntimeProvider);
    final trackingScope = ref.watch(currentScopeProvider);
    // Bind at the persistent shell, regardless of the currently open tab.
    if (runtime.dutyTracker.scope != trackingScope) {
      Future.microtask(() => runtime.bindTrackingScope(trackingScope));
    }
    Widget body;
    final b = boot.value?.bootstrap;
    if (b == null && boot.isLoading) {
      body = const _ShellLoading();
    } else if (b == null && boot.hasError) {
      body = _BootstrapError(
        error: boot.error!,
        retry: () => ref.invalidate(bootstrapProvider),
        signOut: signOut,
      );
    } else {
      body = widget.shell;
    }
    return AppShellScope(
      actions: this,
      child: Scaffold(
        // Keyboard insets are handled here exactly once: the body shrinks and
        // the navigation bar is lifted above the keyboard; pages see no inset.
        resizeToAvoidBottomInset: true,
        body: body,
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (connectionError != null && b != null)
                _ConnectionStrip(retry: checkAccess),
              ListenableBuilder(
                listenable: runtime,
                builder: (context, _) => runtime.tracking
                    ? const _DutyIndicator()
                    : runtime.dutyTracker.needsLocation
                    ? Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          dense: true,
                          leading: const AppIcon(AppIcons.mapPin),
                          title: Text(runtime.trackingStatus),
                          trailing: TextButton(
                            onPressed: runtime.dutyTracker.fixLocation,
                            child: Text(tr('Turn on', 'चालू करें')),
                          ),
                        ),
                      )
                    : runtime
                              .dutyTracker
                              .authorization?['policy']?['enabled'] ==
                          true
                    ? Material(
                        child: ListTile(
                          dense: true,
                          leading: const AppIcon(AppIcons.mapPin),
                          title: Text(runtime.trackingStatus),
                          trailing: const AppIcon(AppIcons.chevronRight),
                          onTap: () => context.go('/work/field-duty'),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              BottomNav(index: widget.shell.currentIndex, onSelect: selectTab),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unread inbox count for the selected site, shown on the Inbox tab.
final inboxUnreadProvider = Provider.autoDispose<int>((ref) {
  final scope = ref.watch(currentScopeProvider);
  if (scope == null) return 0;
  return ref.watch(operationsProvider(scope).select((s) => s.unreadInbox));
});

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key, required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadProvider);
    final t = AppTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.outline)),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          NavigationDestination(
            icon: const AppIcon(AppIcons.house),
            selectedIcon: const AppIcon(AppIcons.house),
            label: tr('Home', 'होम'),
            tooltip: tr('Home', 'होम'),
          ),
          NavigationDestination(
            icon: const AppIcon(AppIcons.briefcaseBusiness),
            selectedIcon: const AppIcon(AppIcons.briefcaseBusiness),
            label: tr('Work', 'कार्य'),
            tooltip: tr('Work', 'कार्य'),
          ),
          NavigationDestination(
            icon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const AppIcon(AppIcons.inbox),
            ),
            selectedIcon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const AppIcon(AppIcons.inbox),
            ),
            label: tr('Inbox', 'इनबॉक्स'),
            tooltip: tr('Inbox', 'इनबॉक्स'),
          ),
          NavigationDestination(
            icon: const AppIcon(AppIcons.userRound),
            selectedIcon: const AppIcon(AppIcons.userRound),
            label: tr('Me', 'मैं'),
            tooltip: tr('Me', 'मैं'),
          ),
        ],
      ),
    );
  }
}

/// Announces that tracking started, then collapses. The OS notification or
/// location indicator remains the persistent signal while sharing continues.
class _DutyIndicator extends StatefulWidget {
  const _DutyIndicator();
  @override
  State<_DutyIndicator> createState() => _DutyIndicatorState();
}

class _DutyIndicatorState extends State<_DutyIndicator> {
  bool visible = true;
  Timer? hide;
  @override
  void initState() {
    super.initState();
    hide = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => visible = false);
    });
  }

  @override
  void dispose() {
    hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    if (!visible) return const SizedBox.shrink();
    return Material(
      color: t.accentPale,
      child: InkWell(
        onTap: () => context.go('/work/field-duty'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.gutter,
            vertical: 8,
          ),
          child: Row(
            children: [
              AppIcon(AppIcons.circleDot, size: 16, color: t.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(
                    'Field duty tracking is on · location is being recorded',
                    'फील्ड ड्यूटी ट्रैकिंग चालू · स्थान दर्ज हो रहा है',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: t.text),
                ),
              ),
              AppIcon(AppIcons.chevronRight, size: 18, color: t.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({required this.retry});
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Material(
      color: t.warningBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: 6,
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.cloudOff, size: 16, color: t.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(
                  'Connection lost. Showing the last loaded data.',
                  'कनेक्शन टूट गया। अंतिम लोड किया डेटा दिख रहा है।',
                ),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: t.warning),
              ),
            ),
            TextButton(
              onPressed: retry,
              style: TextButton.styleFrom(
                foregroundColor: t.warning,
                minimumSize: const Size(48, 36),
              ),
              child: Text(tr('Retry', 'फिर कोशिश')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellLoading extends StatelessWidget {
  const _ShellLoading();
  @override
  Widget build(BuildContext context) => const SafeArea(
    child: Padding(
      padding: Space.page,
      child: LoadingState(rows: 4, rowHeight: 88),
    ),
  );
}

class _BootstrapError extends ConsumerWidget {
  const _BootstrapError({
    required this.error,
    required this.retry,
    required this.signOut,
  });
  final Object error;
  final VoidCallback retry;
  final Future<void> Function() signOut;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: ListView(
      padding: Space.page,
      children: [
        const SizedBox(height: 24),
        EmptyState(
          title: tr(
            'We could not load your workspace',
            'आपका कार्यक्षेत्र लोड नहीं हो सका',
          ),
          message: friendlyError(error),
          illustration: TinyKind.cloud,
          action: ActionButton(
            tr('Try again', 'फिर कोशिश करें'),
            icon: AppIcons.rotateCw,
            expanded: false,
            onPressed: retry,
          ),
        ),
        SectionHeader(tr('Available offline', 'ऑफ़लाइन उपलब्ध')),
        ActionRow(
          icon: AppIcons.lockKeyhole,
          title: tr('Encrypted outbox', 'एन्क्रिप्टेड आउटबॉक्स'),
          subtitle: tr(
            'Queued attendance and comments saved on this device',
            'इस डिवाइस पर सहेजी उपस्थिति और टिप्पणियाँ',
          ),
          onTap: () => context.go('/me/outbox'),
        ),
        ActionRow(
          icon: AppIcons.mic,
          title: tr('Local report drafts', 'स्थानीय रिपोर्ट ड्राफ़्ट'),
          subtitle: tr(
            'Daily report drafts saved on this device',
            'इस डिवाइस पर सहेजे दैनिक रिपोर्ट ड्राफ़्ट',
          ),
          onTap: () => context.go('/work/daily-report'),
        ),
        const SizedBox(height: 16),
        ActionButton(
          tr('Return to sign in', 'साइन इन पर लौटें'),
          variant: ButtonVariant.secondary,
          onPressed: signOut,
        ),
      ],
    ),
  );
}
