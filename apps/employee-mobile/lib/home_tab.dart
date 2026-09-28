import 'ui/icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'approvals.dart';
import 'attendance.dart';
import 'dwr_chat.dart';
import 'dwr_screen.dart';
import 'hr_services.dart';
import 'inbox.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(currentScopeProvider);
    if (scope == null) return ChooseSitePage(title: tr('Home', 'होम'));
    return _HomeBody(key: ValueKey(scope), scope: scope);
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  late final poller = VisiblePoller(
    const Duration(seconds: 25),
    () =>
        ref.read(operationsProvider(widget.scope).notifier).load(silent: true),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    poller.start(context);
  }

  @override
  void dispose() {
    poller.stop();
    super.dispose();
  }

  Future<void> refresh() async {
    ref.invalidate(capabilityProvider(widget.scope));
    ref.invalidate(dwrHomeProvider(widget.scope));
    ref.invalidate(hrQueueProvider(widget.scope));
    ref.invalidate(localDwrDraftsProvider(widget.scope));
    ref.invalidate(dwrChatHomeProvider(widget.scope));
    await ref.read(operationsProvider(widget.scope).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final access = ref.watch(capabilityProvider(scope));
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final caps = access.value?.scope.capabilities ?? const <String>[];
    bool can(String key) => caps.contains(key);
    final profile = can('my_hr.view')
        ? ref.watch(profileProvider(scope)).value?.myProfile
        : null;
    final now = appClock();
    final hour = now.hour;
    final greeting = hour < 12
        ? tr('Good morning', 'सुप्रभात')
        : hour < 17
        ? tr('Good afternoon', 'नमस्कार')
        : tr('Good evening', 'शुभ संध्या');
    final firstName = profile?.displayName.split(' ').first;
    final workDate = access.value?.scope.workDate;
    final dateText = MaterialLocalizations.of(context)
        .formatShortMonthDay(workDate == null ? now : DateTime.parse(workDate));
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting · $dateText',
              style: text.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              firstName ?? tr('Your day', 'आपका दिन'),
              style: text.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          const Center(child: SiteChip(compact: true)),
          const SizedBox(width: 6),
          IconButton(
            tooltip: tr('My profile', 'मेरी प्रोफ़ाइल'),
            onPressed: () => context.go('/me'),
            icon: profile == null
                ? const AppIcon(AppIcons.circleUserRound, size: 30)
                : Avatar(profile.displayName, size: 34),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReadableWidth(
        child: RefreshIndicator(
          onRefresh: refresh,
          color: t.text,
          child: access.when(
            loading: () => ListView(
              padding: Space.page,
              children: const [LoadingState(rows: 3, rowHeight: 120)],
            ),
            error: (e, _) => ListView(
              padding: Space.page,
              children: [
                InlineError(
                  e,
                  retry: () => ref.invalidate(capabilityProvider(scope)),
                ),
              ],
            ),
            data: (data) => ListView(
              padding: Space.page,
              children: [
                if (can('my_attendance.view')) _AttendanceCard(scope: scope),
                if (can('my_dwr.view')) ...[
                  const SizedBox(height: 14),
                  _DailyReportBlock(
                    scope: scope,
                    caps: caps,
                    workDate: data.scope.workDate,
                    quiet: can('my_attendance.view'),
                  ),
                ],
                _Shortcuts(caps: caps),
                _TeamSummary(scope: scope, caps: caps),
                SectionHeader(tr('Needs attention', 'ध्यान दें')),
                _NeedsAttention(
                  scope: scope,
                  caps: caps,
                  workDate: data.scope.workDate,
                ),
                SectionHeader(
                  tr('Recent activity', 'हाल की गतिविधि'),
                  trailing: TextButton(
                    onPressed: () => context.go('/inbox'),
                    child: Text(tr('View all', 'सभी देखें')),
                  ),
                ),
                _RecentActivity(scope: scope),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(operationsProvider(scope));
    final runtime = ref.watch(operationRuntimeProvider);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    if (!ops.loaded) {
      if (ops.error != null) {
        return InlineError(
          ops.error!,
          retry: () => ref.read(operationsProvider(scope).notifier).load(),
        );
      }
      return const LoadingState(rows: 1, rowHeight: 168, header: false);
    }
    if (!ops.configured) {
      return SurfaceCard(
        child: Row(
          children: [
            const TinyIllustration(TinyKind.clock, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      'Attendance is not set up here yet',
                      'यहाँ उपस्थिति अभी सेट नहीं है',
                    ),
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'HR must configure the attendance policy and site boundary first.',
                      'पहले एचआर उपस्थिति नीति और साइट सीमा निर्धारित करे।',
                    ),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return ListenableBuilder(
      listenable: runtime,
      builder: (context, _) {
        final status = attendanceStatus(ops, runtime, scope);
        final controller = ref.read(operationsProvider(scope).notifier);
        final onAccent = t.onAccent;
        Widget pill(String label, IconData icon) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: onAccent.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 14, color: onAccent),
              const SizedBox(width: 5),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: onAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        Future<void> act(String kind) async {
          final result = await controller.capture(
            kind,
            requestOffsiteReason: () => requestAttendanceOutReason(context),
          );
          if (!context.mounted) return;
          switch (result) {
            case CaptureResult.recorded:
              HapticFeedback.lightImpact();
              showConfirmation(
                context,
                kind == 'IN'
                    ? tr('Check-in recorded', 'चेक-इन दर्ज हुआ')
                    : tr('Check-out recorded', 'चेक-आउट दर्ज हुआ'),
              );
            case CaptureResult.queued:
              showConfirmation(
                context,
                tr(
                  'Saved on this device. It will sync when online.',
                  'इस डिवाइस पर सहेजा। ऑनलाइन होने पर सिंक होगा।',
                ),
              );
            case CaptureResult.pendingVerification:
              showConfirmation(
                context,
                '${tr('Recorded. Waiting for verification.', 'दर्ज हुआ। सत्यापन लंबित।')} ${controller.latestCaptureReason == null ? '' : reasonLabel(controller.latestCaptureReason!)}',
              );
            case CaptureResult.cancelled:
            case CaptureResult.failed:
              break;
          }
        }

        return Container(
          padding: const EdgeInsets.all(Space.xl),
          decoration: BoxDecoration(
            gradient: t.accentGradient,
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.awaitingOut
                          ? tr('OUT submitted', 'OUT भेजा गया')
                          : status.verification == 'pending_verification'
                          ? tr('Attendance pending', 'उपस्थिति लंबित')
                          : status.checkedIn
                          ? tr('Checked in', 'चेक-इन हो गया')
                          : tr('Not checked in', 'चेक-इन नहीं हुआ'),
                      style: text.titleMedium?.copyWith(color: onAccent),
                    ),
                  ),
                  if (status.verification == 'pending_verification')
                    pill(
                      tr('Pending verification', 'सत्यापन लंबित'),
                      AppIcons.hourglass,
                    )
                  else if (status.onBreak)
                    pill(tr('On break', 'ब्रेक पर'), AppIcons.coffee)
                  else if (status.onField)
                    pill(
                      tr('On field duty', 'फील्ड ड्यूटी पर'),
                      AppIcons.compass,
                    )
                  else if (status.queued > 0)
                    pill(
                      tr('Waiting to sync', 'सिंक बाकी'),
                      AppIcons.cloudUpload,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (status.confirmedIn &&
                  !status.awaitingOut &&
                  status.since != null) ...[
                ElapsedSince(
                  status.since!,
                  style: text.displaySmall?.copyWith(
                    color: onAccent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tr('Since', 'से')} ${formatTime(context, status.since!.toIso8601String())} · ${ops.snapshot?['siteName'] ?? ''}',
                  style: text.bodySmall?.copyWith(
                    color: onAccent.withValues(alpha: .75),
                  ),
                ),
              ] else
                Text(
                  status.awaitingOut
                      ? tr(
                          'Your OUT is waiting for sync or attendance approval.',
                          'आपका OUT सिंक या अनुमोदन की प्रतीक्षा में है।',
                        )
                      : tr(
                          'Photo check-in records your arrival at this site. GPS is used as evidence, not as proof.',
                          'फोटो चेक-इन इस साइट पर आपकी उपस्थिति दर्ज करता है। जीपीएस प्रमाण नहीं, साक्ष्य है।',
                        ),
                  style: text.bodyMedium?.copyWith(
                    color: onAccent.withValues(alpha: .85),
                  ),
                ),
              if (ops.earlierPendingAttendance > 0)
                Text(
                  tr(
                    '${ops.earlierPendingAttendance} earlier entry(s) still await HR review. Open Attendance for details.',
                    '${ops.earlierPendingAttendance} पुरानी प्रविष्टियों की HR समीक्षा बाकी है। विवरण के लिए उपस्थिति खोलें।',
                  ),
                  style: text.bodySmall?.copyWith(color: onAccent),
                ),
              if (ops.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  friendlyError(ops.error!),
                  style: text.bodySmall?.copyWith(
                    color: t.onAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: onAccent,
                        foregroundColor: t.accent,
                        disabledBackgroundColor: onAccent.withValues(
                          alpha: .35,
                        ),
                      ),
                      onPressed: ops.busy || status.awaitingOut
                          ? null
                          : () => act(status.checkedIn ? 'OUT' : 'IN'),
                      icon: ops.busy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: t.accent,
                              ),
                            )
                          : const AppIcon(AppIcons.camera),
                      label: Text(
                        status.awaitingOut
                            ? tr(
                                'OUT awaiting confirmation',
                                'OUT पुष्टि लंबित',
                              )
                            : status.checkedIn
                            ? tr('Check out with photo', 'फोटो से चेक-आउट')
                            : tr('Check in with photo', 'फोटो से चेक-इन'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    tooltip: tr('Attendance details', 'उपस्थिति विवरण'),
                    style: IconButton.styleFrom(
                      foregroundColor: onAccent,
                      side: BorderSide(color: onAccent.withValues(alpha: .5)),
                      minimumSize: const Size(52, 52),
                    ),
                    onPressed: () => context.go('/work/attendance'),
                    icon: const AppIcon(AppIcons.chevronRight),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DailyReportBlock extends ConsumerWidget {
  const _DailyReportBlock({
    required this.scope,
    required this.caps,
    required this.workDate,
    this.quiet = false,
  });
  final SiteScope scope;
  final List<String> caps;
  final String workDate;
  final bool quiet;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(dwrChatHomeProvider(scope));
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return home.when(
      loading: () => const LoadingState(rows: 1, rowHeight: 96, header: false),
      error: (e, _) => SurfaceCard(
        child: Row(
          children: [
            AppIcon(AppIcons.messagesSquare, color: t.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(
                  'Daily report is unavailable right now.',
                  'दैनिक रिपोर्ट अभी उपलब्ध नहीं है।',
                ),
                style: text.bodyMedium,
              ),
            ),
            IconButton(
              onPressed: () => ref.invalidate(dwrChatHomeProvider(scope)),
              icon: const AppIcon(AppIcons.rotateCw),
              tooltip: tr('Try again', 'फिर कोशिश करें'),
            ),
          ],
        ),
      ),
      data: (data) {
        final today = data['personal']?['today'] as Map?;
        final status = today?['report']?['status'] as String?;
        final count = (today?['messages'] as int?) ?? 0;
        final unread = ((data['groups'] as List?) ?? const []).fold<int>(
          0,
          (sum, g) => sum + ((g['unread'] as int?) ?? 0),
        );
        final pill =
            dwrDayPill(
              today == null ? null : Map<String, dynamic>.from(today),
            ) ??
            StatusPill(
              count == 0
                  ? tr('Not started', 'शुरू नहीं')
                  : tr('$count messages', '$count संदेश'),
            );
        final subtitle = switch (status) {
          'submitted' => tr(
            'Your report for today is with your reviewer.',
            'आज की रिपोर्ट समीक्षक के पास है।',
          ),
          'approved' => tr(
            "Today's report was approved.",
            'आज की रिपोर्ट स्वीकृत हुई।',
          ),
          'returned' => tr(
            'Your reviewer sent the report back with notes.',
            'समीक्षक ने रिपोर्ट टिप्पणी के साथ वापस भेजी।',
          ),
          'draft' => tr(
            'Your DWR was prepared from your chat. Review and submit.',
            'आपकी DWR चैट से तैयार है। जाँचें और भेजें।',
          ),
          _ =>
            count == 0
                ? tr(
                    'Tell your DWR agent what you worked on today, in Hindi, English or Hinglish.',
                    'अपने DWR एजेंट को हिंदी, अंग्रेज़ी या हिंग्लिश में आज का काम बताएँ।',
                  )
                : tr(
                    'Your DWR is prepared automatically from today\'s messages.',
                    'आज के संदेशों से आपकी DWR स्वतः तैयार होगी।',
                  ),
        };
        return SurfaceCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('Daily Report', 'दैनिक रिपोर्ट'),
                      style: text.titleMedium,
                    ),
                  ),
                  Text('DWR', style: text.labelSmall),
                  const SizedBox(width: 8),
                  pill,
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: text.bodyMedium?.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      status == 'draft' || status == 'returned'
                          ? tr('Review & submit', 'जाँचें और भेजें')
                          : tr('Open DWR chat', 'DWR चैट खोलें'),
                      icon: status == 'draft' || status == 'returned'
                          ? AppIcons.clipboardCheck
                          : AppIcons.messagesSquare,
                      variant: status == null && !quiet
                          ? ButtonVariant.primary
                          : ButtonVariant.secondary,
                      onPressed: data['me'] == null
                          ? null
                          : status == 'draft' || status == 'returned'
                          ? () => openDwrForDay(context, ref, scope, workDate)
                          : () => context.go('/work/daily-report'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: tr('Chats and groups', 'चैट और समूह'),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(50, 50),
                      side: BorderSide(color: t.control),
                    ),
                    onPressed: () => context.go('/work/daily-report/chats'),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text(unread > 98 ? '99+' : '$unread'),
                      child: const AppIcon(AppIcons.usersRound),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.caps});
  final List<String> caps;
  @override
  Widget build(BuildContext context) {
    bool can(String k) => caps.contains(k);
    final items = <(IconData, String, String)>[
      if (can('my_attendance.view'))
        (AppIcons.listTodo, tr('Tasks', 'कार्य'), '/work/tasks'),
      if (can('my_leave.view'))
        (
          AppIcons.treePalm,
          tr('Apply for Leave', 'छुट्टी आवेदन'),
          '/work/leave/apply',
        ),
      if (can('my_payroll.view') || can('payroll.view'))
        (
          AppIcons.receiptText,
          tr('View Payslip', 'वेतन पर्ची'),
          recordRoute('payroll'),
        ),
      if (can('expenses.view'))
        (AppIcons.walletCards, tr('Expenses', 'व्यय'), recordRoute('expense')),
      if (can('helpdesk.view'))
        (AppIcons.headset, tr('Helpdesk', 'सहायता'), recordRoute('helpdesk')),
      if (can('my_documents.view'))
        (
          AppIcons.fileText,
          tr('Documents', 'दस्तावेज़'),
          recordRoute('document'),
        ),
    ].take(3).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                onTap: () => context.go(items[i].$3),
                child: Column(
                  children: [
                    AppIconBadge(items[i].$1, size: 38),
                    const SizedBox(height: 8),
                    Text(
                      items[i].$2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: t.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamSummary extends ConsumerWidget {
  const _TeamSummary({required this.scope, required this.caps});
  final SiteScope scope;
  final List<String> caps;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasApprovalCapability(caps)) return const SizedBox.shrink();
    final queue = ref.watch(hrQueueProvider(scope)).value;
    final ops = ref.watch(operationsProvider(scope));
    final dwr = caps.contains('dwr_review.view')
        ? ref.watch(dwrHomeProvider(scope)).value
        : null;
    final counts = approvalCounts(queue, ops, scope, dwr);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        onTap: () => context.go('/work/approvals'),
        child: Row(
          children: [
            const AppIcon(AppIcons.usersRound),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Team', 'टीम'), style: text.titleMedium),
                  Text(
                    counts.total == 0
                        ? tr('No approvals waiting', 'कोई स्वीकृति लंबित नहीं')
                        : tr(
                            '${counts.total} waiting for your decision',
                            '${counts.total} आपके निर्णय की प्रतीक्षा में',
                          ),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            if (counts.total > 0) CountBadge(counts.total),
            const SizedBox(width: 4),
            AppIcon(
              AppIcons.chevronRight,
              color: AppTokens.of(context).textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention({
    required this.scope,
    required this.caps,
    required this.workDate,
  });
  final SiteScope scope;
  final List<String> caps;
  final String workDate;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(operationsProvider(scope));
    final runtime = ref.watch(operationRuntimeProvider);
    final dwr = caps.contains('my_dwr.view')
        ? ref.watch(dwrHomeProvider(scope)).value
        : null;
    final items = <(IconData, String, String, String)>[];
    if (dwr != null) {
      final today = todaysReport(dwr);
      if (today?['status'] == 'returned') {
        items.add((
          AppIcons.notebookPen,
          tr(
            'Your daily report needs changes',
            'आपकी दैनिक रिपोर्ट में बदलाव चाहिए',
          ),
          tr(
            'Open it to see the reviewer notes.',
            'समीक्षक की टिप्पणी देखने के लिए खोलें।',
          ),
          '/work/daily-report',
        ));
      }
    }
    if (ops.loaded) {
      final status = attendanceStatus(ops, runtime, scope);
      if (status.verification == 'pending_verification') {
        items.add((
          AppIcons.hourglass,
          tr(
            'Attendance is waiting for verification',
            'उपस्थिति सत्यापन की प्रतीक्षा में',
          ),
          tr('Not confirmed attendance yet.', 'अभी पुष्ट उपस्थिति नहीं।'),
          '/work/attendance',
        ));
      }
      final now = appClock();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
      for (final task in ops.ownTasks.where((t) => t['status'] != 'done')) {
        final due = parseInstant(task['deadline']);
        if (due != null && due.isBefore(endOfDay)) {
          final overdue = due.isBefore(now);
          items.add((
            AppIcons.listTodo,
            '${task['title']}',
            overdue
                ? tr(
                    'Overdue since ${formatInstant(context, task['deadline'])}',
                    '${formatInstant(context, task['deadline'])} से देरी',
                  )
                : tr(
                    'Due today at ${formatTime(context, task['deadline'])}',
                    'आज ${formatTime(context, task['deadline'])} तक',
                  ),
            '/work/tasks/${task['id']}',
          ));
        }
      }
      for (final v in ops.visits) {
        final at = parseInstant(v['scheduled_at']);
        if (at != null &&
            at.year == now.year &&
            at.month == now.month &&
            at.day == now.day) {
          items.add((
            AppIcons.mapPin,
            '${v['title']}',
            tr(
              'Visit at ${formatTime(context, v['scheduled_at'])}',
              'दौरा ${formatTime(context, v['scheduled_at'])} बजे',
            ),
            '/work/field-duty',
          ));
        }
      }
      if (ops.unreadInbox > 0) {
        items.add((
          AppIcons.inbox,
          (ops.unreadInbox == 1
              ? tr('1 unread message', '1 अपठित संदेश')
              : tr(
                  '${ops.unreadInbox} unread messages',
                  '${ops.unreadInbox} अपठित संदेश',
                )),
          tr(
            'Decisions, alerts and announcements',
            'निर्णय, सूचनाएँ और घोषणाएँ',
          ),
          '/inbox',
        ));
      }
    }
    if (items.isEmpty) {
      return EmptyState(
        title: tr('Nothing needs your attention', 'कुछ भी लंबित नहीं'),
        message: tr(
          'New tasks, returned reports and requests will appear here.',
          'नए कार्य, वापस भेजी रिपोर्ट और अनुरोध यहाँ दिखेंगे।',
        ),
        illustration: TinyKind.check,
      );
    }
    return Column(
      children: [
        for (final (i, item) in items.take(4).indexed)
          ActionRow(
            icon: item.$1,
            title: item.$2,
            subtitle: item.$3,
            onTap: () => context.go(item.$4),
            divider: i < items.take(4).length - 1,
          ),
      ],
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity({required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(operationsProvider(scope));
    if (!ops.loaded) {
      return const LoadingState(rows: 2, header: false, rowHeight: 52);
    }
    final rows = ops.inbox.take(3).toList();
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          tr('No activity yet.', 'अभी कोई गतिविधि नहीं।'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      children: [
        for (final (i, n) in rows.indexed)
          MessageRow(item: Json.from(n), divider: i < rows.length - 1),
      ],
    );
  }
}

/// "View all" destination from Home.
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context) => PageScaffold(
    title: tr('Recent activity', 'हाल की गतिविधि'),
    body: InboxList(scope: scope, filter: InboxFilter.all),
  );
}
