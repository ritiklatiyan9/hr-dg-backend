import 'ui/icons.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'api.dart';
import 'dwr_screen.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';
import 'graphql/operations.graphql.dart';

/// Max characters in one DWR chat message (mirrors packages/contracts/dwr.ts).
const dwrMessageMax = 2000;

Future<DwrJson> dwrChatRead(HrApi api, SiteScope s, DwrJson input) async =>
    Map<String, dynamic>.from(
      (await api.scopedRead(s, documentNodeQueryDwrChat, {
            'input': input,
          }))['dwrChat']
          as Map,
    );

Future<DwrJson> dwrChatCommand(
  HrApi api,
  SiteScope s,
  String operation,
  DwrJson input,
) async => Map<String, dynamic>.from(
  (await api.scopedWrite(s, documentNodeMutationDwrCommand, {
        'operation': operation,
        'input': input,
      }))['dwrCommand']
      as Map,
);

/// Chats list, today's personal DWR status and the agent state for a site.
final dwrChatHomeProvider = FutureProvider.autoDispose
    .family<DwrJson, SiteScope>(
      (ref, s) => dwrChatRead(ref.watch(apiProvider), s, {'view': 'home'}),
    );

String _shiftDay(String ymd, int days) {
  final d = DateTime.parse('${ymd}T00:00:00Z').add(Duration(days: days));
  return d.toIso8601String().substring(0, 10);
}

String dwrDayLabel(BuildContext context, String ymd, String today) =>
    ymd == today
    ? tr('Today', 'आज')
    : ymd == _shiftDay(today, -1)
    ? tr('Yesterday', 'कल')
    : formatDay(context, ymd);

/// Running now, or queued and due now; not the ten-minute quiet-period wait.
bool dwrPreparingNow(DwrJson? day) {
  final job = day?['job'];
  if (job == null) return false;
  if (job['status'] == 'running') return true;
  final due = DateTime.tryParse('${job['dueAt']}');
  return job['status'] == 'queued' &&
      due != null &&
      !due.isAfter(appClock().add(const Duration(seconds: 5)));
}

/// Compact status of one of your own DWR days.
Widget? dwrDayPill(DwrJson? day) {
  final status = day?['report']?['status'];
  if (status == 'approved') {
    return StatusPill(tr('Approved', 'स्वीकृत'), tone: StatusTone.success);
  }
  if (status == 'submitted') {
    return StatusPill(tr('Submitted', 'भेजी गई'), tone: StatusTone.info);
  }
  if (status == 'returned') {
    return StatusPill(tr('Returned', 'वापस भेजी'), tone: StatusTone.warning);
  }
  if (dwrPreparingNow(day)) {
    return StatusPill(
      tr('Preparing', 'तैयार हो रही है'),
      tone: StatusTone.accent,
      icon: AppIcons.ai,
    );
  }
  if (status == 'draft') {
    return StatusPill(
      tr('Draft ready', 'ड्राफ़्ट तैयार'),
      tone: StatusTone.accent,
    );
  }
  if (day?['job']?['status'] == 'queued') {
    return StatusPill(tr('Scheduled', 'निर्धारित'));
  }
  return null;
}

/// Opens the DWR for a day (yours by default) in the report editor.
Future<void> openDwrForDay(
  BuildContext context,
  WidgetRef ref,
  SiteScope scope,
  String workDate, {
  String? employeeId,
}) async {
  final api = ref.read(apiProvider);
  try {
    final caps = (await api.capabilities(scope)).scope.capabilities;
    final data = Map<String, dynamic>.from(
      (await api.scopedRead(scope, documentNodeQueryDwr, {
        'workDate': workDate,
      }))['dwr'],
    );
    final report = (data['reports'] as List)
        .cast<Map>()
        .where(
          (r) => employeeId == null
              ? r['isSelf'] == true
              : r['employee_id'] == employeeId,
        )
        .firstOrNull;
    if (!context.mounted) return;
    if (report == null) {
      showConfirmation(
        context,
        tr(
          'No DWR for this day yet. It is prepared from the day\'s messages.',
          'इस दिन की DWR अभी नहीं है। यह उस दिन के संदेशों से तैयार होती है।',
        ),
      );
      return;
    }
    await openReportEditor(
      context,
      ref,
      scope: scope,
      data: data,
      caps: caps,
      report: Map<String, dynamic>.from(report),
    );
  } catch (e) {
    if (context.mounted) showConfirmation(context, friendlyError(e));
  }
}

// ---------------------------------------------------------------------------
// Landing: your DWR agent chat, whole month by default.
// ---------------------------------------------------------------------------

class DwrHomePage extends ConsumerWidget {
  const DwrHomePage({super.key, required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(dwrChatHomeProvider(scope));
    if (home.hasValue && home.value!['me'] == null) {
      return DwrChatsPage(scope: scope);
    }
    return DwrChatPage(scope: scope, groupId: null, landing: true);
  }
}

// ---------------------------------------------------------------------------
// Chats list
// ---------------------------------------------------------------------------

class DwrChatsPage extends ConsumerWidget {
  const DwrChatsPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(dwrChatHomeProvider(scope));
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: tr('DWR chats', 'DWR चैट'),
      actions: [
        if (home.value?['permissions']?['createGroups'] == true)
          IconButton(
            tooltip: tr('New group', 'नया समूह'),
            icon: const AppIcon(AppIcons.userRoundPlus),
            onPressed: () => context.push('/work/daily-report/new-group'),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dwrChatHomeProvider(scope)),
        child: home.when(
          loading: () => ListView(
            padding: Space.page,
            children: const [LoadingState(rows: 4, rowHeight: 64)],
          ),
          error: (e, _) => ListView(
            padding: Space.page,
            children: [
              InlineError(
                e,
                retry: () => ref.invalidate(dwrChatHomeProvider(scope)),
              ),
            ],
          ),
          data: (h) {
            final groups = (h['groups'] as List).cast<Map>();
            final personal = h['personal'] as Map?;
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (h['me'] != null)
                  _ChatTile(
                    leading: _AiAvatar(size: 48),
                    title: tr('My DWR Agent', 'मेरा DWR एजेंट'),
                    subtitle: personal?['last'] == null
                        ? tr(
                            'Tell your agent what you worked on today',
                            'अपने एजेंट को आज का काम बताएँ',
                          )
                        : personal!['last']['deleted'] == true
                        ? tr('Message deleted', 'संदेश हटाया गया')
                        : '${personal['last']['body']}',
                    time: personal?['last']?['at'],
                    trailing: dwrDayPill(
                      personal?['today'] == null
                          ? null
                          : Map<String, dynamic>.from(personal!['today']),
                    ),
                    onTap: () => context.go('/work/daily-report'),
                  ),
                if (groups.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      16,
                      Space.gutter,
                      4,
                    ),
                    child: Text(
                      tr('Groups', 'समूह'),
                      style: text.labelLarge?.copyWith(color: t.textSecondary),
                    ),
                  ),
                for (final g in groups)
                  _ChatTile(
                    leading: Avatar('${g['name']}', size: 48),
                    title: '${g['name']}',
                    subtitle: g['last'] == null
                        ? tr('No messages yet', 'अभी कोई संदेश नहीं')
                        : '${g['last']['author'] ?? tr('Member', 'सदस्य')}: ${g['last']['deleted'] == true ? tr('message deleted', 'संदेश हटाया गया') : g['last']['body']}',
                    time: g['last']?['at'],
                    unread: g['unread'] as int? ?? 0,
                    trailing: g['archived'] == true
                        ? StatusPill(tr('Archived', 'संग्रहीत'))
                        : g['role'] == null
                        ? StatusPill(tr('View only', 'केवल देखें'))
                        : null,
                    onTap: () =>
                        context.push('/work/daily-report/chat/${g['id']}'),
                  ),
                if (groups.isEmpty)
                  Padding(
                    padding: Space.page,
                    child: EmptyState(
                      title: tr('No groups yet', 'अभी कोई समूह नहीं'),
                      message: tr(
                        'Team DWR groups created by HR or your admins appear here.',
                        'HR या एडमिन के बनाए टीम DWR समूह यहाँ दिखेंगे।',
                      ),
                      illustration: TinyKind.people,
                      action: h['permissions']?['createGroups'] == true
                          ? ActionButton(
                              tr('Create a group', 'समूह बनाएँ'),
                              icon: AppIcons.userRoundPlus,
                              expanded: false,
                              onPressed: () =>
                                  context.push('/work/daily-report/new-group'),
                            )
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.time,
    this.unread = 0,
    this.trailing,
  });
  final Widget leading;
  final String title, subtitle;
  final dynamic time;
  final int unread;
  final Widget? trailing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: 10,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                      ),
                      if (time != null)
                        Text(
                          relativeTime(context, time),
                          style: text.labelSmall?.copyWith(
                            color: unread > 0 ? t.accent : t.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unread > 98 ? '99+' : '$unread',
                            style: text.labelSmall?.copyWith(
                              color: t.onAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
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

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => AppIconBadge(AppIcons.ai, size: size);
}

// ---------------------------------------------------------------------------
// One chat: personal agent (groupId == null) or a group, a month at a time.
// ---------------------------------------------------------------------------

class DwrChatPage extends ConsumerStatefulWidget {
  const DwrChatPage({
    super.key,
    required this.scope,
    required this.groupId,
    this.landing = false,
  });
  final SiteScope scope;
  final String? groupId;
  final bool landing;
  @override
  ConsumerState<DwrChatPage> createState() => _DwrChatPageState();
}

class _DwrChatPageState extends ConsumerState<DwrChatPage> {
  DwrJson? data;
  final messages = <String, DwrJson>{};
  Object? error;
  String? month, since, lastReadId;
  bool loadingOlder = false, sending = false;
  final input = TextEditingController();
  final scroll = ScrollController();
  late final VisiblePoller poller = VisiblePoller(
    const Duration(seconds: 5),
    refresh,
  );
  int generation = 0;
  Future<void>? refreshTask;

  HrApi get api => ref.read(apiProvider);

  @override
  void initState() {
    super.initState();
    load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) poller.start(context);
    });
  }

  @override
  void dispose() {
    poller.stop();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final g = ++generation;
    since = null;
    try {
      final d = await dwrChatRead(api, widget.scope, {
        'view': 'thread',
        'groupId': widget.groupId,
        'month': ?month,
      });
      if (!mounted || g != generation) return;
      setState(() {
        data = d;
        month = d['month'];
        since = d['serverTime'];
        messages
          ..removeWhere((_, m) => m['pending'] == null)
          ..addAll({
            for (final m in (d['messages'] as List))
              '${m['id']}': Map<String, dynamic>.from(m),
          });
        error = null;
      });
      markRead();
    } catch (e) {
      if (mounted && g == generation) setState(() => error = e);
    }
  }

  Future<void> refresh() {
    if (refreshTask != null) return refreshTask!;
    final task = refreshOnce();
    refreshTask = task;
    unawaited(
      task
          .whenComplete(() {
            if (identical(refreshTask, task)) refreshTask = null;
          })
          .catchError((Object _) {}),
    );
    return task;
  }

  Future<void> refreshOnce() async {
    if (since == null || data == null) return;
    final g = generation;
    try {
      final d = await dwrChatRead(api, widget.scope, {
        'view': 'thread',
        'groupId': widget.groupId,
        'month': month,
        'since': since,
      });
      if (!mounted || g != generation) return;
      setState(() {
        data = {...d, 'hasMore': data!['hasMore'], 'before': data!['before']};
        since = d['serverTime'];
        for (final m in (d['messages'] as List)) {
          final known = messages['${m['id']}'];
          if (known == null ||
              (known['version'] as int) <= (m['version'] as int)) {
            messages['${m['id']}'] = Map<String, dynamic>.from(m);
          }
        }
      });
      markRead();
    } catch (_) {
      /* The next poll retries; failures surface on explicit actions. */
    }
  }

  Future<void> loadOlder() async {
    final before = data?['before'];
    if (before == null || loadingOlder) return;
    setState(() => loadingOlder = true);
    try {
      final d = await dwrChatRead(api, widget.scope, {
        'view': 'thread',
        'groupId': widget.groupId,
        'month': month,
        'before': before,
      });
      if (!mounted) return;
      setState(() {
        for (final m in (d['messages'] as List)) {
          messages['${m['id']}'] = Map<String, dynamic>.from(m);
        }
        data = {...data!, 'hasMore': d['hasMore'], 'before': d['before']};
      });
    } catch (e) {
      if (mounted) showConfirmation(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => loadingOlder = false);
    }
  }

  void markRead() {
    final thread = data?['thread'];
    if (widget.groupId == null || thread?['role'] == null) return;
    final newest = ordered().lastOrNull?['id'];
    if (newest == null || newest == lastReadId) return;
    lastReadId = '$newest';
    dwrChatCommand(api, widget.scope, 'markRead', {
      'groupId': widget.groupId,
    }).then((_) {
      if (mounted) ref.invalidate(dwrChatHomeProvider(widget.scope));
    }, onError: (_) {});
  }

  List<DwrJson> ordered() {
    final list = messages.values.toList()
      ..sort((a, b) {
        final c = '${a['createdAt']}'.compareTo('${b['createdAt']}');
        return c != 0 ? c : '${a['id']}'.compareTo('${b['id']}');
      });
    return list;
  }

  Future<void> send(String body, [String? retryClientId]) async {
    final me = data?['me'];
    if (me == null) return;
    final clientId = retryClientId ?? const Uuid().v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final localId = 'local-$clientId';
    setState(() {
      messages[localId] = {
        'id': localId,
        'clientId': clientId,
        'userId': me['userId'],
        'workDate': data!['workDate'],
        'body': body,
        'version': 0,
        'createdAt': now,
        'updatedAt': now,
        'mine': true,
        'pending': 'sending',
      };
    });
    HapticFeedback.selectionClick();
    try {
      final r = await dwrChatCommand(api, widget.scope, 'message', {
        'clientId': clientId,
        'groupId': widget.groupId,
        'body': body,
      });
      await refresh();
      if (!mounted) return;
      setState(() => messages.remove(localId));
      ref.invalidate(dwrChatHomeProvider(widget.scope));
      if (r['reportLocked'] == true) {
        showConfirmation(
          context,
          tr(
            "Today's DWR is already submitted, so this message is not added to it.",
            'आज की DWR पहले ही भेजी जा चुकी है, यह संदेश उसमें नहीं जुड़ेगा।',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => messages[localId] = {...messages[localId]!, 'pending': 'failed'},
      );
      showConfirmation(context, friendlyError(e));
    }
  }

  Future<void> messageActions(DwrJson m) async {
    if (m['pending'] != null || m['deletedAt'] != null) return;
    final choice = await showAppSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon(AppIcons.copy),
              title: Text(tr('Copy text', 'पाठ कॉपी करें')),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            if (m['canEdit'] == true)
              ListTile(
                leading: const AppIcon(AppIcons.pencil),
                title: Text(tr('Edit', 'संपादित करें')),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            if (m['canDelete'] == true)
              ListTile(
                leading: AppIcon(
                  AppIcons.trash2,
                  color: AppTokens.of(ctx).error,
                ),
                title: Text(
                  m['mine'] == true
                      ? tr('Delete', 'हटाएँ')
                      : tr('Remove as moderator', 'मॉडरेटर के रूप में हटाएँ'),
                  style: TextStyle(color: AppTokens.of(ctx).error),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'copy') {
      await Clipboard.setData(ClipboardData(text: '${m['body']}'));
      if (mounted) showConfirmation(context, tr('Copied', 'कॉपी किया'));
    } else if (choice == 'edit') {
      final next = await showAppSheet<String>(
        context,
        builder: (ctx) => _EditSheet(initial: '${m['body']}'),
      );
      if (next == null || next.trim().isEmpty || next.trim() == m['body']) {
        return;
      }
      await guarded(
        () => dwrChatCommand(api, widget.scope, 'editMessage', {
          'id': m['id'],
          'expectedVersion': m['version'],
          'body': next.trim(),
        }),
      );
    } else if (choice == 'delete') {
      final ok = await confirmDialog(
        context,
        title: tr('Delete message?', 'संदेश हटाएँ?'),
        message: m['mine'] == true
            ? tr(
                'It is removed from this chat and from your DWR. The original stays in the audit history.',
                'यह चैट और आपकी DWR से हट जाएगा। मूल संदेश ऑडिट इतिहास में रहेगा।',
              )
            : tr(
                'You are removing another person\'s message as a moderator. Everyone will see that it was removed.',
                'आप मॉडरेटर के रूप में किसी और का संदेश हटा रहे हैं। सभी को दिखेगा कि इसे हटाया गया।',
              ),
        confirmLabel: tr('Delete', 'हटाएँ'),
        destructive: true,
      );
      if (!ok) return;
      await guarded(
        () => dwrChatCommand(api, widget.scope, 'deleteMessage', {
          'id': m['id'],
          'expectedVersion': m['version'],
        }),
      );
    }
  }

  Future<void> guarded(Future<void> Function() action) async {
    try {
      await action();
      await refresh();
      ref.invalidate(dwrChatHomeProvider(widget.scope));
    } catch (e) {
      if (mounted) showConfirmation(context, friendlyError(e));
    }
  }

  Future<void> pickMonth() async {
    final today = '${data?['workDate'] ?? ''}';
    if (today.length < 7) return;
    final base = DateTime.utc(
      int.parse(today.substring(0, 4)),
      int.parse(today.substring(5, 7)),
    );
    final months = [
      for (var i = 0; i < 12; i++)
        DateTime.utc(
          base.year,
          base.month - i,
        ).toIso8601String().substring(0, 7),
    ];
    final picked = await showAppSheet<String>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              tr('Show month', 'महीना दिखाएँ'),
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          for (final m in months)
            ListTile(
              title: Text(formatMonth(ctx, '$m-01')),
              trailing: m == month ? const AppIcon(AppIcons.check) : null,
              onTap: () => Navigator.pop(ctx, m),
            ),
        ],
      ),
    );
    if (picked == null || picked == month) return;
    setState(() {
      month = picked;
      data = null;
      messages.clear();
    });
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final d = data;
    final personal = widget.groupId == null;
    final thread = d?['thread'] as Map?;
    final title = personal
        ? tr('My DWR Agent', 'मेरा DWR एजेंट')
        : '${thread?['name'] ?? tr('Group', 'समूह')}';
    final home = ref.watch(dwrChatHomeProvider(widget.scope)).value;
    final unread = ((home?['groups'] as List?) ?? const []).fold<int>(
      0,
      (sum, g) => sum + ((g['unread'] as int?) ?? 0),
    );
    final subtitle = d == null
        ? ''
        : personal
        ? (d['agent']?['online'] == true
              ? tr(
                  'AI agent online · prepares your DWR',
                  'AI एजेंट ऑनलाइन · आपकी DWR तैयार करता है',
                )
              : tr(
                  'Private · your chat is your report',
                  'निजी · आपकी चैट ही आपकी रिपोर्ट',
                ))
        : '${thread?['memberCount']} ${tr('members', 'सदस्य')}${thread?['role'] == 'admin'
              ? ' · ${tr('Admin', 'एडमिन')}'
              : thread?['role'] == null
              ? ' · ${tr('View only', 'केवल देखें')}'
              : ''}';
    final days = {
      for (final day in (d?['days'] as List? ?? const []))
        '${day['workDate']}': Map<String, dynamic>.from(day),
    };
    final today = '${d?['workDate'] ?? ''}';
    final currentMonth = today.length >= 7 && month == today.substring(0, 7);
    // Newest first for a reversed list; day separators follow each day's first message.
    final list = ordered();
    final items = <Widget>[];
    for (var i = list.length - 1; i >= 0; i--) {
      final m = list[i];
      final previous = i > 0 ? list[i - 1] : null;
      final newDay = previous == null || previous['workDate'] != m['workDate'];
      final showAuthor =
          !personal &&
          m['mine'] != true &&
          (newDay || previous['userId'] != m['userId']);
      items.add(
        _Bubble(
          key: ValueKey(m['id']),
          m: m,
          author:
              '${(d?['people'] as Map?)?[m['userId']] ?? tr('Member', 'सदस्य')}',
          showAuthor: showAuthor,
          onLongPress: () => messageActions(m),
          onRetry: m['pending'] == 'failed'
              ? () {
                  setState(() => messages.remove(m['id']));
                  send('${m['body']}', '${m['clientId']}');
                }
              : null,
        ),
      );
      if (newDay) {
        final day = days['${m['workDate']}'];
        items.add(
          _DaySeparator(
            label: dwrDayLabel(context, '${m['workDate']}', today),
            pill: d?['me'] == null ? null : dwrDayPill(day),
            onTap: day?['report'] == null
                ? null
                : () => openDwrForDay(
                    context,
                    ref,
                    widget.scope,
                    '${m['workDate']}',
                  ).then((_) => refresh()),
          ),
        );
      }
    }
    return PageScaffold(
      title: title,
      showSite: false,
      titleWidget: InkWell(
        onTap: personal || widget.groupId == null
            ? null
            : () => context
                  .push('/work/daily-report/chat/${widget.groupId}/info')
                  .then((_) => load()),
        child: Row(
          children: [
            personal ? const _AiAvatar(size: 36) : Avatar(title, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: tr('Show month', 'महीना दिखाएँ'),
          icon: const AppIcon(AppIcons.calendarDays),
          onPressed: d == null ? null : pickMonth,
        ),
        if (widget.landing)
          IconButton(
            tooltip: tr('Chats and groups', 'चैट और समूह'),
            onPressed: () => context.push('/work/daily-report/chats'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 98 ? '99+' : '$unread'),
              child: const AppIcon(AppIcons.messagesSquare),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: tr('More', 'और'),
          onSelected: (v) {
            if (v == 'reports') context.push('/work/daily-report/reports');
            if (v == 'info') {
              context
                  .push('/work/daily-report/chat/${widget.groupId}/info')
                  .then((_) => load());
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'reports',
              child: Text(tr('My reports', 'मेरी रिपोर्ट')),
            ),
            if (!personal)
              PopupMenuItem(
                value: 'info',
                child: Text(tr('Group info', 'समूह जानकारी')),
              ),
          ],
        ),
      ],
      body: error != null && d == null
          ? ListView(
              padding: Space.page,
              children: [InlineError(error!, retry: load)],
            )
          : d == null
          ? const Padding(
              padding: Space.page,
              child: LoadingState(rows: 5, rowHeight: 48, header: false),
            )
          : Container(
              color: t.canvas,
              child: items.isEmpty
                  ? ListView(
                      padding: Space.page,
                      children: [
                        const SizedBox(height: 40),
                        EmptyState(
                          title: personal
                              ? tr(
                                  'What did you work on today?',
                                  'आज आपने क्या काम किया?',
                                )
                              : tr(
                                  'No messages this month',
                                  'इस महीने कोई संदेश नहीं',
                                ),
                          message: personal
                              ? tr(
                                  'Write in Hindi, English or Hinglish, or tap your keyboard\'s mic to speak. Your DWR is prepared from your messages automatically.',
                                  'हिंदी, अंग्रेज़ी या हिंग्लिश में लिखें, या बोलने के लिए कीबोर्ड का माइक दबाएँ। आपकी DWR आपके संदेशों से स्वतः तैयार होगी।',
                                )
                              : tr(
                                  'Messages sent in this group appear here.',
                                  'इस समूह के संदेश यहाँ दिखेंगे।',
                                ),
                          illustration: TinyKind.clipboard,
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: scroll,
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: items.length + 1,
                      itemBuilder: (context, i) {
                        if (i < items.length) return items[i];
                        return d['hasMore'] == true
                            ? Center(
                                child: TextButton.icon(
                                  onPressed: loadingOlder ? null : loadOlder,
                                  icon: loadingOlder
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const AppIcon(
                                          AppIcons.history,
                                          size: 18,
                                        ),
                                  label: Text(
                                    tr(
                                      'Load earlier messages',
                                      'पहले के संदेश',
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(height: 8);
                      },
                    ),
            ),
      bottom: d == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (d['me'] != null &&
                    thread?['canPost'] == true &&
                    currentMonth)
                  _DayBar(
                    scope: widget.scope,
                    workDate: today,
                    day: days[today],
                    messagesToday:
                        ((home?['personal'] as Map?)?['today']?['messages']
                            as int?) ??
                        0,
                    online: d['agent']?['online'] == true,
                    onChanged: () async {
                      await refresh();
                      ref.invalidate(dwrChatHomeProvider(widget.scope));
                    },
                  ),
                if (thread?['canPost'] == true)
                  _Composer(controller: input, onSend: (b) => send(b))
                else
                  Container(
                    width: double.infinity,
                    color: t.surface,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: SafeArea(
                      top: false,
                      child: Text(
                        thread?['archived'] == true
                            ? tr(
                                'This group is archived. Messages are read-only.',
                                'यह समूह संग्रहीत है। संदेश केवल पढ़े जा सकते हैं।',
                              )
                            : thread?['role'] == null && !personal
                            ? tr(
                                'View only. Only members can send messages.',
                                'केवल देखें। केवल सदस्य संदेश भेज सकते हैं।',
                              )
                            : tr(
                                'Sending DWR messages is not permitted for your account at this site.',
                                'इस साइट पर आपके खाते को DWR संदेश भेजने की अनुमति नहीं है।',
                              ),
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label, this.pill, this.onTap});
  final String label;
  final Widget? pill;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: t.outline),
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          if (pill != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: pill,
            ),
          ],
        ],
      ),
    );
  }
}

const _authorColorsLight = [
  Color(0xFF0F766E),
  Color(0xFF6D28D9),
  Color(0xFFB45309),
  Color(0xFF1D4ED8),
  Color(0xFFBE185D),
  Color(0xFF15803D),
];
const _authorColorsDark = [
  Color(0xFF5EEAD4),
  Color(0xFFC4B5FD),
  Color(0xFFFCD34D),
  Color(0xFF93C5FD),
  Color(0xFFF9A8D4),
  Color(0xFF86EFAC),
];

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.m,
    required this.author,
    required this.showAuthor,
    required this.onLongPress,
    this.onRetry,
  });
  final DwrJson m;
  final String author;
  final bool showAuthor;
  final VoidCallback onLongPress;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final mine = m['mine'] == true, deleted = m['deletedAt'] != null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark ? _authorColorsDark : _authorColorsLight;
    final color =
        palette['${m['userId']}'.codeUnits.fold<int>(
              7,
              (a, c) => (a * 31 + c) & 0x7fffffff,
            ) %
            palette.length];
    final fg = deleted
        ? t.textSecondary
        : mine
        ? t.onAccent
        : t.text;
    final meta = (deleted
        ? t.textSecondary
        : mine
        ? t.onAccent.withValues(alpha: .78)
        : t.textSecondary);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .8,
        ),
        child: Padding(
          padding: EdgeInsets.only(top: showAuthor ? 6 : 2, bottom: 2),
          child: Semantics(
            label:
                '${mine ? tr('You', 'आप') : author}: ${deleted ? tr('message deleted', 'संदेश हटाया गया') : m['body']}',
            child: Material(
              color: deleted
                  ? Colors.transparent
                  : mine
                  ? t.accent
                  : t.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
                side: mine && !deleted
                    ? BorderSide.none
                    : BorderSide(color: t.outline),
              ),
              child: InkWell(
                onLongPress: onLongPress,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showAuthor)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            author,
                            style: text.labelMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        deleted
                            ? (m['deletedByModerator'] == true
                                  ? tr(
                                      'Removed by a moderator',
                                      'मॉडरेटर ने हटाया',
                                    )
                                  : tr(
                                      'This message was deleted',
                                      'यह संदेश हटाया गया',
                                    ))
                            : '${m['body']}',
                        style: text.bodyLarge?.copyWith(
                          color: fg,
                          fontStyle: deleted ? FontStyle.italic : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m['editedAt'] != null && !deleted) ...[
                            Text(
                              tr('edited', 'संपादित'),
                              style: text.labelSmall?.copyWith(color: meta),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            formatTime(context, m['createdAt']),
                            style: text.labelSmall?.copyWith(color: meta),
                          ),
                          if (mine && !deleted) ...[
                            const SizedBox(width: 4),
                            AppIcon(
                              m['pending'] == 'sending'
                                  ? AppIcons.clock3
                                  : m['pending'] == 'failed'
                                  ? AppIcons.circleAlert
                                  : AppIcons.checkCheck,
                              size: 14,
                              color: m['pending'] == 'failed'
                                  ? t.errorBg
                                  : meta,
                              semanticLabel: m['pending'] == 'sending'
                                  ? tr('Sending', 'भेजा जा रहा है')
                                  : m['pending'] == 'failed'
                                  ? tr('Not sent', 'नहीं भेजा गया')
                                  : tr('Sent', 'भेजा गया'),
                            ),
                          ],
                        ],
                      ),
                      if (onRetry != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: t.onAccent,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: onRetry,
                          icon: const AppIcon(AppIcons.rotateCw, size: 16),
                          label: Text(tr('Tap to retry', 'फिर भेजें')),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final void Function(String body) onSend;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(changed);
    super.dispose();
  }

  void changed() => setState(() {});

  void submit() {
    final body = widget.controller.text.trim();
    if (body.isEmpty) return;
    widget.onSend(body);
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final empty = widget.controller.text.trim().isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              // The phone's own keyboard: its mic key dictates Hindi, English or Hinglish.
              child: TextField(
                key: const ValueKey('dwr-composer'),
                controller: widget.controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                maxLength: dwrMessageMax,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => currentLength > dwrMessageMax - 200
                    ? Text('${dwrMessageMax - currentLength}')
                    : null,
                decoration: InputDecoration(
                  hintText: tr(
                    'Type, or tap the keyboard mic to speak…',
                    'लिखें, या बोलने के लिए कीबोर्ड माइक दबाएँ…',
                  ),
                  filled: true,
                  fillColor: t.canvas,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: t.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: t.outline),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: IconButton.filled(
                tooltip: tr('Send', 'भेजें'),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: t.accent,
                  foregroundColor: t.onAccent,
                ),
                onPressed: empty ? null : submit,
                icon: const AppIcon(AppIcons.sendHorizontal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.initial});
  final String initial;
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Edit message', 'संदेश संपादित करें'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('dwr-edit-field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 8,
          maxLength: dwrMessageMax,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                tr('Cancel', 'रद्द करें'),
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                tr('Save', 'सहेजें'),
                onPressed: () => Navigator.pop(context, controller.text),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Today's DWR in one line above the composer, with the next useful action.
class _DayBar extends ConsumerStatefulWidget {
  const _DayBar({
    required this.scope,
    required this.workDate,
    required this.day,
    required this.messagesToday,
    required this.online,
    required this.onChanged,
  });
  final SiteScope scope;
  final String workDate;
  final DwrJson? day;
  final int messagesToday;
  final bool online;
  final Future<void> Function() onChanged;
  @override
  ConsumerState<_DayBar> createState() => _DayBarState();
}

class _DayBarState extends ConsumerState<_DayBar> {
  bool busy = false;
  Future<void> prepare(String mode) async {
    setState(() => busy = true);
    try {
      final r = await dwrChatCommand(
        ref.read(apiProvider),
        widget.scope,
        'prepare',
        {'workDate': widget.workDate, 'mode': mode},
      );
      await widget.onChanged();
      if (!mounted) return;
      if (mode == 'chat') {
        await openDwrForDay(context, ref, widget.scope, widget.workDate);
        await widget.onChanged();
      } else if (r['outcome'] == 'QUEUED') {
        showConfirmation(
          context,
          widget.online
              ? tr(
                  'Preparing your DWR. It appears here in a few seconds.',
                  'आपकी DWR तैयार हो रही है। कुछ सेकंड में दिखेगी।',
                )
              : tr(
                  'Queued. The AI agent prepares it when it is back online.',
                  'कतार में है। AI एजेंट ऑनलाइन होने पर तैयार करेगा।',
                ),
        );
      }
    } catch (e) {
      if (mounted) showConfirmation(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final status = widget.day?['report']?['status'];
    final job = widget.day?['job'];
    String message;
    final actions = <Widget>[];
    Future<void> open() => openDwrForDay(
      context,
      ref,
      widget.scope,
      widget.workDate,
    ).then((_) => widget.onChanged());
    if (status == 'submitted' || status == 'approved') {
      message = status == 'approved'
          ? tr("Today's DWR was approved.", 'आज की DWR स्वीकृत हुई।')
          : tr(
              "Today's DWR is with your reviewer.",
              'आज की DWR समीक्षक के पास है।',
            );
      actions.add(
        TextButton(onPressed: open, child: Text(tr('View', 'देखें'))),
      );
    } else if (dwrPreparingNow(widget.day)) {
      message = tr(
        'Your agent is preparing today\'s DWR…',
        'आपका एजेंट आज की DWR तैयार कर रहा है…',
      );
    } else if (status == 'draft' || status == 'returned') {
      message = status == 'returned'
          ? tr(
              'Sent back. Review and resend.',
              'वापस भेजी गई। जाँचकर फिर भेजें।',
            )
          : job?['status'] == 'queued'
          ? tr(
              'DWR ready · newer messages are added in a few minutes.',
              'DWR तैयार · नए संदेश कुछ मिनटों में जुड़ेंगे।',
            )
          : tr(
              "Today's DWR is ready to submit.",
              'आज की DWR भेजने के लिए तैयार है।',
            );
      actions.add(
        FilledButton(
          onPressed: busy ? null : open,
          child: Text(tr('Review', 'जाँचें')),
        ),
      );
    } else if (widget.messagesToday == 0) {
      message = tr(
        'Tell your agent what you did today. Your DWR is prepared automatically.',
        'एजेंट को आज का काम बताएँ। आपकी DWR स्वतः तैयार होगी।',
      );
    } else {
      message = job?['status'] == 'failed'
          ? tr(
              'The agent could not prepare it yet. Send your chat as the report, or try again.',
              'एजेंट अभी तैयार नहीं कर सका। चैट को रिपोर्ट भेजें या फिर कोशिश करें।',
            )
          : widget.online
          ? tr(
              'Auto-prepared 10 min after your last message.',
              'आखिरी संदेश के 10 मिनट बाद स्वतः तैयार।',
            )
          : tr(
              'AI agent offline. You can send your chat as the report.',
              'AI एजेंट ऑफ़लाइन। चैट को ही रिपोर्ट भेज सकते हैं।',
            );
      actions.add(
        TextButton(
          onPressed: busy ? null : () => prepare('chat'),
          child: Text(tr('Use chat', 'चैट भेजें')),
        ),
      );
      if (widget.online) {
        actions.add(
          FilledButton(
            onPressed: busy ? null : () => prepare('ai'),
            child: Text(tr('Prepare', 'तैयार करें')),
          ),
        );
      }
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.accentPale,
        border: Border(top: BorderSide(color: t.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      child: Row(
        children: [
          AppIcon(AppIcons.ai, size: 18, color: t.text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(color: t.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ...actions,
        ],
      ),
    );
  }
}

/// The day's chat messages behind a DWR, for its author and reviewers.
class DwrDaySources extends ConsumerStatefulWidget {
  const DwrDaySources({
    super.key,
    required this.scope,
    required this.employeeId,
    required this.workDate,
  });
  final SiteScope scope;
  final String? employeeId;
  final String workDate;
  @override
  ConsumerState<DwrDaySources> createState() => _DwrDaySourcesState();
}

class _DwrDaySourcesState extends ConsumerState<DwrDaySources> {
  List<Map>? rows;
  @override
  void initState() {
    super.initState();
    dwrChatRead(ref.read(apiProvider), widget.scope, {
      'view': 'day',
      'employeeId': ?widget.employeeId,
      'workDate': widget.workDate,
    }).then(
      (d) {
        if (mounted) setState(() => rows = (d['messages'] as List).cast<Map>());
      },
      onError: (_) {
        if (mounted) setState(() => rows = const []);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          tr('Chat messages for this day', 'इस दिन के चैट संदेश'),
          subtitle: tr(
            'The employee\'s own words this report is based on',
            'कर्मचारी के अपने शब्द, जिनसे यह रिपोर्ट बनी',
          ),
        ),
        if (rows == null)
          const LoadingState(rows: 2, rowHeight: 40, header: false)
        else if (rows!.isEmpty)
          Text(
            tr(
              'No chat messages are visible for this day.',
              'इस दिन के कोई चैट संदेश नहीं दिखे।',
            ),
            style: text.bodySmall,
          )
        else
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in rows!)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatTime(context, m['createdAt'])} · ${m['groupId'] == null ? tr('Agent chat', 'एजेंट चैट') : m['groupName'] ?? tr('Group', 'समूह')}${m['editedAt'] != null ? ' · ${tr('edited', 'संपादित')}' : ''}',
                          style: text.labelSmall?.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('${m['body']}', style: text.bodyMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Group info: members, WhatsApp-style admins, add people, leave, archive.
// ---------------------------------------------------------------------------

class DwrGroupInfoPage extends ConsumerStatefulWidget {
  const DwrGroupInfoPage({
    super.key,
    required this.scope,
    required this.groupId,
  });
  final SiteScope scope;
  final String groupId;
  @override
  ConsumerState<DwrGroupInfoPage> createState() => _DwrGroupInfoPageState();
}

class _DwrGroupInfoPageState extends ConsumerState<DwrGroupInfoPage> {
  DwrJson? info;
  Object? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await dwrChatRead(ref.read(apiProvider), widget.scope, {
        'view': 'group',
        'groupId': widget.groupId,
      });
      if (mounted) {
        setState(() {
          info = d;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<bool> act(String op, DwrJson input, String done) async {
    setState(() => busy = true);
    try {
      await dwrChatCommand(ref.read(apiProvider), widget.scope, op, input);
      ref.invalidate(dwrChatHomeProvider(widget.scope));
      if (mounted) showConfirmation(context, done);
      await load();
      return true;
    } catch (e) {
      if (mounted) showConfirmation(context, friendlyError(e));
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> memberActions(Map m) async {
    final i = info!;
    final choice = await showAppSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${m['name']}',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            if (m['role'] == 'member')
              ListTile(
                leading: const AppIcon(AppIcons.shieldUser),
                title: Text(tr('Make group admin', 'समूह एडमिन बनाएँ')),
                onTap: () => Navigator.pop(ctx, 'admin'),
              )
            else
              ListTile(
                leading: const AppIcon(AppIcons.shieldOff),
                title: Text(tr('Dismiss as admin', 'एडमिन से हटाएँ')),
                onTap: () => Navigator.pop(ctx, 'member'),
              ),
            if (m['me'] != true)
              ListTile(
                leading: AppIcon(
                  AppIcons.userRoundMinus,
                  color: AppTokens.of(ctx).error,
                ),
                title: Text(
                  tr('Remove from group', 'समूह से हटाएँ'),
                  style: TextStyle(color: AppTokens.of(ctx).error),
                ),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'remove') {
      final ok = await confirmDialog(
        context,
        title: tr('Remove ${m['name']}?', '${m['name']} को हटाएँ?'),
        message: tr(
          'They stop seeing this group. Their messages and DWRs are kept.',
          'वे यह समूह नहीं देख पाएँगे। उनके संदेश और DWR सुरक्षित रहेंगे।',
        ),
        confirmLabel: tr('Remove', 'हटाएँ'),
        destructive: true,
      );
      if (!ok) return;
      await act('removeMember', {
        'id': i['id'],
        'userId': m['userId'],
      }, tr('Removed', 'हटाया गया'));
    } else {
      await act(
        'setMemberRole',
        {'id': i['id'], 'userId': m['userId'], 'role': choice},
        choice == 'admin'
            ? tr('Made group admin', 'समूह एडमिन बनाया')
            : tr('Dismissed as admin', 'एडमिन से हटाया'),
      );
    }
  }

  Future<void> addPeople() async {
    final picked = await showAppSheet<Map>(
      context,
      builder: (ctx) => _PeoplePicker(
        scope: widget.scope,
        groupId: widget.groupId,
        exclude: {for (final m in (info!['members'] as List)) '${m['userId']}'},
      ),
    );
    if (picked == null) return;
    await act('addMembers', {
      'id': widget.groupId,
      'userIds': [picked['userId']],
    }, tr('${picked['name']} added', '${picked['name']} जोड़े गए'));
  }

  Future<void> editDetails() async {
    final i = info!;
    final result = await showAppSheet<(String, String)>(
      context,
      builder: (ctx) => _GroupDetailsSheet(
        name: '${i['name']}',
        description: '${i['description']}',
      ),
    );
    if (result == null) return;
    await act('updateGroup', {
      'id': i['id'],
      'expectedVersion': i['version'],
      'name': result.$1,
      'description': result.$2,
    }, tr('Group updated', 'समूह अपडेट हुआ'));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final i = info;
    return PageScaffold(
      title: tr('Group info', 'समूह जानकारी'),
      showSite: false,
      actions: [
        if (i?['canManage'] == true)
          IconButton(
            tooltip: tr('Edit details', 'विवरण संपादित करें'),
            icon: const AppIcon(AppIcons.pencil),
            onPressed: busy ? null : editDetails,
          ),
      ],
      body: error != null && i == null
          ? ListView(
              padding: Space.page,
              children: [InlineError(error!, retry: load)],
            )
          : i == null
          ? const Padding(
              padding: Space.page,
              child: LoadingState(rows: 4, rowHeight: 56),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: Space.page,
                children: [
                  Center(child: Avatar('${i['name']}', size: 84)),
                  const SizedBox(height: 12),
                  Text(
                    '${i['name']}',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall,
                  ),
                  if ('${i['description']}'.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${i['description']}',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: t.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${(i['members'] as List).length} ${tr('members', 'सदस्य')}${i['createdBy'] != null ? ' · ${tr('Created by', 'बनाया')} ${i['createdBy']}' : ''}',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                  if (i['archived'] == true) ...[
                    const SizedBox(height: 10),
                    Center(child: StatusPill(tr('Archived', 'संग्रहीत'))),
                  ],
                  SectionHeader(
                    '${(i['members'] as List).length} ${tr('members', 'सदस्य')}',
                    trailing: i['canManage'] == true
                        ? TextButton.icon(
                            onPressed: busy ? null : addPeople,
                            icon: const AppIcon(
                              AppIcons.userRoundPlus,
                              size: 18,
                            ),
                            label: Text(tr('Add', 'जोड़ें')),
                          )
                        : null,
                  ),
                  for (final (n, m)
                      in (i['members'] as List).cast<Map>().indexed)
                    Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Avatar('${m['name']}', size: 42),
                          title: Text(
                            m['me'] == true
                                ? '${m['name']} (${tr('you', 'आप')})'
                                : '${m['name']}',
                          ),
                          trailing: m['role'] == 'admin'
                              ? StatusPill(
                                  tr('Group admin', 'समूह एडमिन'),
                                  tone: StatusTone.accent,
                                )
                              : null,
                          onTap: i['canManage'] == true && !busy
                              ? () => memberActions(m)
                              : null,
                        ),
                        if (n < (i['members'] as List).length - 1)
                          const Divider(height: 1),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (i['canLeave'] == true)
                    ActionButton(
                      tr('Leave group', 'समूह छोड़ें'),
                      icon: AppIcons.logOut,
                      variant: ButtonVariant.danger,
                      onPressed: busy
                          ? null
                          : () async {
                              final ok = await confirmDialog(
                                context,
                                title: tr(
                                  'Leave this group?',
                                  'यह समूह छोड़ें?',
                                ),
                                message: tr(
                                  'You stop seeing its messages. If you are the last admin, the longest-standing member becomes admin.',
                                  'आप इसके संदेश नहीं देख पाएँगे। यदि आप अंतिम एडमिन हैं, तो सबसे पुराने सदस्य एडमिन बनेंगे।',
                                ),
                                confirmLabel: tr('Leave', 'छोड़ें'),
                                destructive: true,
                              );
                              if (!ok || !mounted) return;
                              if (await act(
                                    'leaveGroup',
                                    {'id': i['id']},
                                    tr('You left the group', 'आपने समूह छोड़ा'),
                                  ) &&
                                  context.mounted) {
                                context.go('/work/daily-report/chats');
                              }
                            },
                    ),
                  if (i['canArchive'] == true) ...[
                    const SizedBox(height: 8),
                    ActionButton(
                      tr('Archive group', 'समूह संग्रहीत करें'),
                      icon: AppIcons.archive,
                      variant: ButtonVariant.danger,
                      onPressed: busy
                          ? null
                          : () async {
                              final decision = await askDecision(
                                context,
                                title: tr(
                                  'Archive this group?',
                                  'यह समूह संग्रहीत करें?',
                                ),
                                message: tr(
                                  'Members can no longer send messages. Messages and DWRs are kept.',
                                  'सदस्य संदेश नहीं भेज पाएँगे। संदेश और DWR सुरक्षित रहेंगे।',
                                ),
                                decision: false,
                              );
                              if (decision == null) return;
                              await act('archiveGroup', {
                                'id': i['id'],
                                'expectedVersion': i['version'],
                                'reason': decision.note,
                              }, tr('Group archived', 'समूह संग्रहीत हुआ'));
                            },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _GroupDetailsSheet extends StatefulWidget {
  const _GroupDetailsSheet({required this.name, required this.description});
  final String name, description;
  @override
  State<_GroupDetailsSheet> createState() => _GroupDetailsSheetState();
}

class _GroupDetailsSheetState extends State<_GroupDetailsSheet> {
  late final name = TextEditingController(text: widget.name);
  late final description = TextEditingController(text: widget.description);
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Group details', 'समूह विवरण'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        AppTextField(label: tr('Group name', 'समूह का नाम'), controller: name),
        AppTextField(
          label: tr('Description', 'विवरण'),
          controller: description,
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        ActionButton(
          tr('Save', 'सहेजें'),
          onPressed: () {
            if (name.text.trim().length < 2) return;
            Navigator.pop(context, (name.text.trim(), description.text.trim()));
          },
        ),
      ],
    ),
  );
}

/// Server-searched people at this site; minimal labels only.
class _PeoplePicker extends ConsumerStatefulWidget {
  const _PeoplePicker({
    required this.scope,
    this.groupId,
    this.exclude = const {},
  });
  final SiteScope scope;
  final String? groupId;
  final Set<String> exclude;
  @override
  ConsumerState<_PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends ConsumerState<_PeoplePicker> {
  final search = TextEditingController();
  Timer? debounce;
  List<Map>? people;
  Object? error;
  @override
  void initState() {
    super.initState();
    find();
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> find() async {
    try {
      final d = await dwrChatRead(ref.read(apiProvider), widget.scope, {
        'view': 'candidates',
        'groupId': widget.groupId,
        'search': search.text.trim(),
      });
      if (mounted) {
        setState(() {
          people = (d['people'] as List).cast<Map>();
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = (people ?? const [])
        .where((p) => !widget.exclude.contains('${p['userId']}'))
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: search,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const AppIcon(AppIcons.search),
                hintText: tr(
                  'Search people at this site',
                  'इस साइट के लोग खोजें',
                ),
              ),
              onChanged: (_) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 250), find);
              },
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: InlineError(error!, retry: find, compact: true),
            )
          else if (people == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingState(rows: 3, rowHeight: 44, header: false),
            )
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(tr('No one found.', 'कोई नहीं मिला।')),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in shown)
                    ListTile(
                      leading: Avatar('${p['name']}', size: 38),
                      title: Text('${p['name']}'),
                      trailing: const AppIcon(AppIcons.circlePlus),
                      onTap: () => Navigator.pop(context, p),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New group
// ---------------------------------------------------------------------------

class DwrNewGroupPage extends ConsumerStatefulWidget {
  const DwrNewGroupPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<DwrNewGroupPage> createState() => _DwrNewGroupPageState();
}

class _DwrNewGroupPageState extends ConsumerState<DwrNewGroupPage> {
  final name = TextEditingController(), description = TextEditingController();
  final members = <Map<String, dynamic>>[];
  final clientId = const Uuid().v4();
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final p = await showAppSheet<Map>(
      context,
      builder: (ctx) => _PeoplePicker(
        scope: widget.scope,
        exclude: {for (final m in members) '${m['userId']}'},
      ),
    );
    if (p != null) {
      setState(
        () => members.add({
          ...Map<String, dynamic>.from(p),
          'admin': members.isEmpty,
        }),
      );
    }
  }

  Future<void> create() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await dwrChatCommand(
        ref.read(apiProvider),
        widget.scope,
        'createGroup',
        {
          'clientId': clientId,
          'name': name.text.trim(),
          'description': description.text.trim(),
          'members': [
            for (final m in members)
              {'userId': m['userId'], 'admin': m['admin'] == true},
          ],
        },
      );
      ref.invalidate(dwrChatHomeProvider(widget.scope));
      if (!mounted) return;
      showConfirmation(context, tr('Group created', 'समूह बनाया गया'));
      context.pushReplacement('/work/daily-report/chat/${r['id']}');
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valid =
        name.text.trim().length >= 2 &&
        members.isNotEmpty &&
        members.any((m) => m['admin'] == true);
    return PageScaffold(
      title: tr('New DWR group', 'नया DWR समूह'),
      showSite: false,
      body: ListView(
        padding: Space.page,
        children: [
          Text(
            tr(
              'Members post their daily work here. Each member\'s DWR is prepared from their own messages.',
              'सदस्य यहाँ दैनिक काम लिखते हैं। हर सदस्य की DWR उनके अपने संदेशों से बनती है।',
            ),
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: tr('Group name', 'समूह का नाम'),
            controller: name,
            onChanged: (_) => setState(() {}),
          ),
          AppTextField(
            label: tr('Description', 'विवरण'),
            controller: description,
            minLines: 2,
            maxLines: 4,
          ),
          SectionHeader(
            tr('Members', 'सदस्य'),
            trailing: TextButton.icon(
              onPressed: busy ? null : pick,
              icon: const AppIcon(AppIcons.userRoundPlus, size: 18),
              label: Text(tr('Add people', 'लोग जोड़ें')),
            ),
          ),
          if (members.isEmpty)
            Text(
              tr(
                'Add at least one person and choose a group admin.',
                'कम से कम एक व्यक्ति जोड़ें और समूह एडमिन चुनें।',
              ),
              style: text.bodySmall,
            ),
          for (final m in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar('${m['name']}', size: 40),
              title: Text('${m['name']}'),
              subtitle: Text(
                m['admin'] == true
                    ? tr('Group admin', 'समूह एडमिन')
                    : tr('Member', 'सदस्य'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: m['admin'] == true,
                    onChanged: (v) => setState(() => m['admin'] = v),
                  ),
                  IconButton(
                    tooltip: tr('Remove', 'हटाएँ'),
                    icon: const AppIcon(AppIcons.x),
                    onPressed: () => setState(() => members.remove(m)),
                  ),
                ],
              ),
            ),
          if (error != null) InlineError(error!),
        ],
      ),
      bottom: ActionPanel(
        children: [
          ActionButton(
            tr('Create group', 'समूह बनाएँ'),
            icon: AppIcons.userRoundPlus,
            busy: busy,
            onPressed: valid ? create : null,
          ),
        ],
      ),
    );
  }
}
