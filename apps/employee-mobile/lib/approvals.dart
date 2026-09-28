import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'attendance.dart';
import 'dwr_screen.dart';
import 'hr_services.dart';
import 'leave.dart';
import 'mobile_ui.dart';
import 'scope.dart';
import 'ui/components.dart';

bool hasApprovalCapability(List<String> caps) => caps.any(
  (c) =>
      c.endsWith('.approve') ||
      c.endsWith('.review') ||
      c.endsWith('.manage') ||
      c == 'attendance.approve' ||
      c == 'leave.approve',
);

class ApprovalCounts {
  const ApprovalCounts({this.queue = 0, this.events = 0});
  final int queue, events;
  int get total => queue + events;
}

/// Server-authorized queue items plus attendance evidence waiting for this
/// actor's independent verification.
ApprovalCounts approvalCounts(
  HrMap? queue,
  OperationsState ops,
  SiteScope scope,
  Map? dwr,
) {
  final items = (queue?['items'] as List?)?.length ?? 0;
  final events = ops.approverId == scope.actorId
      ? ops.events.where((e) => e['status'] == 'pending_verification').length
      : 0;
  return ApprovalCounts(queue: items, events: events);
}

String queueKindLabel(String kind) => switch (kind) {
  'leave' => tr('Leave', 'छुट्टी'),
  'attendance' => tr('Attendance correction', 'उपस्थिति सुधार'),
  'dwr' => tr('Daily report', 'दैनिक रिपोर्ट'),
  'payroll' => tr('Payroll', 'वेतन'),
  _ =>
    hrNames.containsKey(kind) ? tr(hrNames[kind]![0], hrNames[kind]![1]) : kind,
};

class ApprovalsPage extends ConsumerStatefulWidget {
  const ApprovalsPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends ConsumerState<ApprovalsPage> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final queue = ref.watch(hrQueueProvider(scope));
    final ops = ref.watch(operationsProvider(scope));
    final text = Theme.of(context).textTheme;
    Future<void> refresh() async {
      ref.invalidate(hrQueueProvider(scope));
      ref.invalidate(dwrHomeProvider(scope));
      await ref.read(operationsProvider(scope).notifier).load();
    }

    return PageScaffold(
      title: tr('Approvals', 'स्वीकृतियाँ'),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: queue.when(
          loading: () => ListView(
            padding: Space.page,
            children: const [LoadingState(rows: 4)],
          ),
          error: (e, _) => ListView(
            padding: Space.page,
            children: [InlineError(e, retry: refresh)],
          ),
          data: (q) {
            final items = (q['items'] as List? ?? [])
                .map((e) => HrMap.from(e as Map))
                .toList();
            final pendingEvents = ops.approverId == scope.actorId
                ? ops.events
                      .where((e) => e['status'] == 'pending_verification')
                      .toList()
                : const <Json>[];
            final kinds = {
              ...items.map((i) => '${i['kind']}'),
              if (pendingEvents.isNotEmpty) 'evidence',
            };
            final visible = items
                .where((i) => filter == 'all' || '${i['kind']}' == filter)
                .toList();
            final showEvidence = filter == 'all' || filter == 'evidence';
            return ListView(
              padding: Space.page,
              children: [
                if (kinds.length > 1)
                  FilterBar<String>(
                    value: filter,
                    onChanged: (v) => setState(() => filter = v),
                    items: [
                      ('all', tr('All', 'सभी')),
                      for (final k in kinds)
                        (
                          k,
                          k == 'evidence'
                              ? tr('Attendance evidence', 'उपस्थिति साक्ष्य')
                              : queueKindLabel(k),
                        ),
                    ],
                  ),
                if (ops.offline)
                  NoticeBanner(
                    tr('Approvals are online-only.', 'स्वीकृति केवल ऑनलाइन।'),
                    tone: StatusTone.warning,
                  ),
                if (visible.isEmpty && (!showEvidence || pendingEvents.isEmpty))
                  EmptyState(
                    title: tr('Nothing to approve', 'कुछ स्वीकृत करने को नहीं'),
                    message: tr(
                      'Requests that need your independent decision appear here.',
                      'आपके स्वतंत्र निर्णय की ज़रूरत वाले अनुरोध यहाँ दिखेंगे।',
                    ),
                    illustration: TinyKind.check,
                  ),
                for (final item in visible)
                  _QueueRow(scope: scope, item: item, ops: ops),
                if (showEvidence && pendingEvents.isNotEmpty) ...[
                  SectionHeader(
                    tr('Attendance evidence', 'उपस्थिति साक्ष्य'),
                    subtitle: tr(
                      'Independent review of pending check-ins',
                      'लंबित चेक-इन की स्वतंत्र समीक्षा',
                    ),
                  ),
                  for (final (i, e) in pendingEvents.indexed)
                    ActionRow(
                      icon: AppIcons.hourglass,
                      title: kindLabel('${e['kind']}'),
                      subtitle:
                          '${formatInstant(context, e['captured_at'])}\n${reasonLabel('${e['reason'] ?? ''}')}',
                      trailing: StatusPill(
                        tr('Pending', 'लंबित'),
                        tone: StatusTone.warning,
                      ),
                      divider: i < pendingEvents.length - 1,
                      onTap: ops.offline
                          ? null
                          : () => verifyEventFlow(context, ref, scope, e),
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  tr(
                    'You cannot approve your own requests. Every decision needs a written reason.',
                    'आप अपने अनुरोध स्वीकृत नहीं कर सकते। हर निर्णय के लिए लिखित कारण आवश्यक है।',
                  ),
                  style: text.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({required this.scope, required this.item, required this.ops});
  final SiteScope scope;
  final HrMap item;
  final OperationsState ops;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = '${item['kind']}', id = '${item['id']}';
    final leave = kind == 'leave'
        ? ops.leaveRequests.where((l) => l['id'] == id).firstOrNull
        : null;
    final adjustment = kind == 'attendance'
        ? ops.adjustments.where((a) => a['id'] == id).firstOrNull
        : null;
    String subtitle = formatInstant(context, item['updated_at']);
    if (leave != null) {
      subtitle =
          '${leaveTypeLabel(ops, leave['type_id'])} · ${unitsText(leave['units'])} · ${formatDay(context, leave['starts_on'])}';
    } else if (adjustment != null) {
      subtitle =
          '${segmentLabel('${adjustment['kind']}')} · ${formatInstant(context, adjustment['starts_at'])}';
    }
    return ActionRow(
      icon: switch (kind) {
        'leave' => AppIcons.treePalm,
        'attendance' => AppIcons.calendarCog,
        'dwr' => AppIcons.mic,
        'payroll' => AppIcons.receiptText,
        'expense' => AppIcons.walletCards,
        'asset' => AppIcons.monitorSmartphone,
        'helpdesk' || 'grievance' => AppIcons.headset,
        _ => AppIcons.fileText,
      },
      title: queueKindLabel(kind),
      subtitle: subtitle,
      trailing: StatusPill.status('${item['status']}'),
      onTap: ops.offline
          ? null
          : () {
              if (leave != null) {
                reviewLeaveFlow(context, ref, scope, leave);
              } else if (adjustment != null) {
                reviewAdjustmentFlow(context, ref, scope, adjustment);
              } else if (kind == 'dwr') {
                context.go('/work/daily-report?queue=team');
              } else {
                context.go('/work/records/$kind/$id');
              }
            },
    );
  }
}
