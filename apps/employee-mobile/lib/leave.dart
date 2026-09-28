import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'attendance.dart';
import 'mobile_ui.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';

String leaveTypeLabel(OperationsState ops, dynamic typeId) {
  final type = ops.leaveTypes.where((t) => t['id'] == typeId).firstOrNull;
  return '${type?['label'] ?? type?['code'] ?? tr('Leave', 'छुट्टी')}';
}

String portionLabel(dynamic half) => switch ('$half') {
  'am' => tr('First half', 'पहला आधा'),
  'pm' => tr('Second half', 'दूसरा आधा'),
  _ => tr('Full day', 'पूरा दिन'),
};

String unitsText(dynamic units) {
  final n = double.tryParse('$units') ?? 0;
  final s = n == n.roundToDouble()
      ? n.toInt().toString()
      : n.toStringAsFixed(1);
  return tr('$s day${n == 1 ? '' : 's'}', '$s दिन');
}

class LeavePage extends ConsumerWidget {
  const LeavePage({super.key, required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(operationsProvider(scope));
    final controller = ref.read(operationsProvider(scope).notifier);
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return PageScaffold(
      title: tr('Leave', 'छुट्टी'),
      body: RefreshIndicator(
        onRefresh: () => controller.load(),
        child: !ops.loaded
            ? ListView(
                padding: Space.page,
                children: [
                  if (ops.error != null)
                    InlineError(ops.error!, retry: controller.load)
                  else
                    const LoadingState(rows: 3),
                ],
              )
            : ListView(
                padding: Space.page,
                children: [
                  if (ops.offline)
                    NoticeBanner(
                      tr(
                        'Offline · leave requests are queued on this device when allowed.',
                        'ऑफ़लाइन · अनुमति होने पर छुट्टी अनुरोध इस डिवाइस पर कतार में।',
                      ),
                      tone: StatusTone.warning,
                    ),
                  SectionHeader(tr('Balances', 'शेष'), top: 4),
                  if (ops.balances.isEmpty)
                    Text(
                      ops.leaveTypes.isEmpty
                          ? tr(
                              'Leave rules and credits must be configured by HR.',
                              'छुट्टी नियम और क्रेडिट एचआर द्वारा निर्धारित होने चाहिए।',
                            )
                          : tr(
                              'No leave credits yet.',
                              'अभी कोई छुट्टी क्रेडिट नहीं।',
                            ),
                      style: text.bodyMedium,
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final b in ops.balances)
                          Container(
                            constraints: const BoxConstraints(minWidth: 130),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: t.accentPale,
                              borderRadius: BorderRadius.circular(Radii.m),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unitsText(b['balance']),
                                  style: text.titleLarge,
                                ),
                                Text(
                                  leaveTypeLabel(ops, b['type_id']),
                                  style: text.bodySmall?.copyWith(
                                    color: t.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  ActionButton(
                    tr('Apply for Leave', 'छुट्टी आवेदन'),
                    icon: AppIcons.plus,
                    onPressed: ops.leaveTypes.isEmpty
                        ? null
                        : () => context.go('/work/leave/apply'),
                  ),
                  SectionHeader(tr('Your requests', 'आपके अनुरोध')),
                  if (ops.ownLeave.isEmpty)
                    EmptyState(
                      title: tr(
                        'No leave requests yet',
                        'अभी कोई छुट्टी अनुरोध नहीं',
                      ),
                      message: tr(
                        'Applications and decisions appear here with their approval timeline.',
                        'आवेदन और निर्णय यहाँ स्वीकृति समयरेखा के साथ दिखेंगे।',
                      ),
                      illustration: TinyKind.calendar,
                    ),
                  for (final l in ops.ownLeave)
                    _LeaveCard(ops: ops, request: l),
                ],
              ),
      ),
    );
  }
}

class _LeaveCard extends StatefulWidget {
  const _LeaveCard({required this.ops, required this.request});
  final OperationsState ops;
  final Json request;
  @override
  State<_LeaveCard> createState() => _LeaveCardState();
}

class _LeaveCardState extends State<_LeaveCard> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final l = widget.request;
    final text = Theme.of(context).textTheme;
    final status = '${l['status']}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        onTap: () => setState(() => open = !open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${leaveTypeLabel(widget.ops, l['type_id'])} · ${unitsText(l['units'])}',
                        style: text.titleMedium,
                      ),
                      Text(
                        l['starts_on'] == l['ends_on']
                            ? '${formatDay(context, l['starts_on'])} · ${portionLabel(l['half'])}'
                            : '${formatDay(context, l['starts_on'])} → ${formatDay(context, l['ends_on'])}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusPill.status(status),
              ],
            ),
            AnimatedSize(
              duration: Motion.medium,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text('${l['reason']}', style: text.bodyMedium),
                        const SizedBox(height: 10),
                        TimelineRow(
                          title: tr('Requested', 'अनुरोध किया'),
                          time: formatTime(context, l['created_at']),
                          subtitle: formatDay(
                            context,
                            parseInstant(
                              l['created_at'],
                            )?.toIso8601String().substring(0, 10),
                          ),
                          kind: TimelineKind.start,
                          first: true,
                        ),
                        TimelineRow(
                          title: status == 'pending'
                              ? tr(
                                  'Waiting for approval',
                                  'स्वीकृति की प्रतीक्षा',
                                )
                              : statusLabel(status),
                          time: status == 'pending'
                              ? ''
                              : formatTime(
                                  context,
                                  l['decided_at'] ?? l['updated_at'],
                                ),
                          subtitle: l['decision_note'] == null
                              ? (status == 'pending'
                                    ? tr(
                                        'Your approver will decide.',
                                        'आपका अनुमोदक निर्णय लेगा।',
                                      )
                                    : null)
                              : '${l['decision_note']}',
                          kind: status == 'pending'
                              ? TimelineKind.pending
                              : status == 'approved'
                              ? TimelineKind.start
                              : TimelineKind.end,
                          last: true,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApplyLeavePage extends ConsumerStatefulWidget {
  const ApplyLeavePage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends ConsumerState<ApplyLeavePage> {
  late final UnsavedWork unsaved;
  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
  }

  final form = GlobalKey<FormState>();
  final reason = TextEditingController();
  String? typeId, startsOn, endsOn;
  String half = 'full';
  bool busy = false;
  Object? error;
  void dirty() => ref
      .read(unsavedWorkProvider)
      .mark(
        'apply-leave',
        tr('Leave application', 'छुट्टी आवेदन'),
        reason.text.isNotEmpty || startsOn != null,
      );
  @override
  void dispose() {
    unsaved.mark('apply-leave', '', false);
    reason.dispose();
    super.dispose();
  }

  int get calendarDays {
    final s = DateTime.tryParse(startsOn ?? ''),
        e = DateTime.tryParse(endsOn ?? '');
    if (s == null || e == null || e.isBefore(s)) return 0;
    return e.difference(s).inDays + 1;
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final input = {
      'clientId': const Uuid().v4(),
      'typeId': typeId,
      'startsOn': startsOn,
      'endsOn': endsOn,
      'half': half,
      'reason': reason.text.trim(),
    };
    try {
      final controller = ref.read(operationsProvider(widget.scope).notifier);
      final ops = ref.read(operationsProvider(widget.scope));
      if (ops.offline) {
        await controller.runtime.enqueue(widget.scope, 'leave', input);
        if (mounted) {
          showConfirmation(
            context,
            tr(
              'Saved on this device. It will be sent when online.',
              'इस डिवाइस पर सहेजा। ऑनलाइन होने पर भेजा जाएगा।',
            ),
          );
        }
      } else {
        await controller.command('leave', input);
        if (mounted) {
          showConfirmation(
            context,
            tr('Leave request sent', 'छुट्टी अनुरोध भेजा गया'),
          );
        }
      }
      unsaved.mark('apply-leave', '', false);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(operationsProvider(widget.scope));
    final text = Theme.of(context).textTheme;
    final balance = typeId == null
        ? null
        : ops.balances.where((b) => b['type_id'] == typeId).firstOrNull;
    return PageScaffold(
      title: tr('Apply for Leave', 'छुट्टी आवेदन'),
      body: Form(
        key: form,
        onChanged: dirty,
        child: FormPageBody(
          fields: [
            AppDropdown<String>(
              label: tr('Leave type', 'छुट्टी का प्रकार'),
              value: typeId,
              hint: tr('Choose a type', 'प्रकार चुनें'),
              items: [
                for (final t in ops.leaveTypes)
                  (t['id'] as String, '${t['label'] ?? t['code']}'),
              ],
              validator: (v) => v == null
                  ? tr('Choose a leave type', 'छुट्टी का प्रकार चुनें')
                  : null,
              onChanged: (v) => setState(() => typeId = v),
              help: balance == null
                  ? null
                  : '${tr('Available', 'उपलब्ध')}: ${unitsText(balance['balance'])}',
            ),
            DateField(
              label: tr('From', 'से'),
              value: startsOn,
              validator: (v) => v == null ? tr('Required', 'आवश्यक') : null,
              onChanged: (v) => setState(() {
                startsOn = v;
                endsOn ??= v;
                if (endsOn != null && v != null && endsOn!.compareTo(v) < 0) {
                  endsOn = v;
                }
                dirty();
              }),
            ),
            DateField(
              label: tr('To', 'तक'),
              value: endsOn,
              validator: (v) => v == null
                  ? tr('Required', 'आवश्यक')
                  : startsOn != null && v.compareTo(startsOn!) < 0
                  ? tr(
                      'End must not be before start',
                      'समाप्ति आरंभ से पहले न हो',
                    )
                  : null,
              onChanged: (v) => setState(() {
                endsOn = v;
                dirty();
              }),
            ),
            ChoiceChips<String>(
              label: tr('Portion', 'हिस्सा'),
              value: half,
              items: [
                ('full', tr('Full day', 'पूरा दिन')),
                ('am', tr('First half', 'पहला आधा')),
                ('pm', tr('Second half', 'दूसरा आधा')),
              ],
              onChanged: (v) => setState(() => half = v),
              help: calendarDays == 0
                  ? null
                  : tr(
                      '$calendarDays calendar day(s). Working days and leave units are confirmed by the site leave rules when the request is recorded.',
                      '$calendarDays कैलेंडर दिन। कार्य दिवस और छुट्टी इकाइयाँ दर्ज होने पर साइट नियमों से तय होंगी।',
                    ),
            ),
            AppTextField(
              label: tr('Reason', 'कारण'),
              controller: reason,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              help: tr('At least 8 characters', 'कम से कम 8 अक्षर'),
              validator: (v) => (v?.trim().length ?? 0) < 8
                  ? tr('Use at least 8 characters', 'कम से कम 8 अक्षर लिखें')
                  : null,
            ),
            if (error != null) InlineError(error!),
            if (ops.offline)
              Text(
                tr(
                  'You are offline. The request will be queued on this device.',
                  'आप ऑफ़लाइन हैं। अनुरोध इस डिवाइस पर कतार में रहेगा।',
                ),
                style: text.bodySmall,
              ),
          ],
          actions: [
            ActionButton(
              tr('Send for approval', 'स्वीकृति के लिए भेजें'),
              icon: AppIcons.sendHorizontal,
              busy: busy,
              onPressed: busy ? null : submit,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> reviewLeaveFlow(
  BuildContext context,
  WidgetRef ref,
  SiteScope scope,
  Json l,
) async {
  final ops = ref.read(operationsProvider(scope));
  final result = await askDecision(
    context,
    title: tr('Review leave request', 'छुट्टी अनुरोध समीक्षा'),
    message:
        '${leaveTypeLabel(ops, l['type_id'])} · ${unitsText(l['units'])}\n${formatDay(context, l['starts_on'])} → ${formatDay(context, l['ends_on'])}\n${l['reason']}',
  );
  if (result == null) return false;
  try {
    await ref.read(operationsProvider(scope).notifier).command('reviewLeave', {
      'id': l['id'],
      'expectedVersion': l['version'],
      'approve': result.approve,
      'reason': result.note,
    });
    if (context.mounted) {
      showConfirmation(
        context,
        result.approve
            ? tr('Leave approved', 'छुट्टी स्वीकृत')
            : tr('Leave rejected', 'छुट्टी अस्वीकृत'),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
    return false;
  }
}
