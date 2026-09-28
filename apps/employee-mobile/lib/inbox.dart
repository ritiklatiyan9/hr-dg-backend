import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';
import 'attendance.dart';
import 'hr_services.dart';
import 'me_tab.dart' show personalEntries;
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';
import 'graphql/operations.graphql.dart';
import 'graphql/schema.graphql.dart';

enum InboxFilter { all, unread, requests, announcements }

class InboxTab extends ConsumerWidget {
  const InboxTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(currentScopeProvider);
    if (scope == null) {
      return TabRoot(child: ChooseSitePage(title: tr('Inbox', 'इनबॉक्स')));
    }
    return TabRoot(
      child: _InboxBody(key: ValueKey(scope), scope: scope),
    );
  }
}

class _InboxBody extends ConsumerStatefulWidget {
  const _InboxBody({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<_InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends ConsumerState<_InboxBody> {
  InboxFilter filter = InboxFilter.all;
  @override
  Widget build(BuildContext context) {
    final caps =
        ref.watch(capabilityProvider(widget.scope)).value?.scope.capabilities ??
        const <String>[];
    final showRequests =
        caps.contains('my_hr.view') || caps.contains('employees.review');
    final showAnnouncements = caps.contains('announcements.view');
    return PageScaffold(
      title: tr('Inbox', 'इनबॉक्स'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              4,
              Space.gutter,
              4,
            ),
            child: FilterBar<InboxFilter>(
              value: filter,
              onChanged: (v) => setState(() => filter = v),
              items: [
                (InboxFilter.all, tr('All', 'सभी')),
                (InboxFilter.unread, tr('Unread', 'अपठित')),
                if (showRequests)
                  (InboxFilter.requests, tr('Requests', 'अनुरोध')),
                if (showAnnouncements)
                  (InboxFilter.announcements, tr('Announcements', 'घोषणाएँ')),
              ],
            ),
          ),
          Expanded(
            child: InboxList(
              scope: widget.scope,
              filter: filter,
              canApprove: caps.contains('employees.approve'),
            ),
          ),
        ],
      ),
    );
  }
}

class InboxList extends ConsumerWidget {
  const InboxList({
    super.key,
    required this.scope,
    required this.filter,
    this.canApprove = false,
  });
  final SiteScope scope;
  final InboxFilter filter;
  final bool canApprove;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(operationsProvider(scope));
    final controller = ref.read(operationsProvider(scope).notifier);
    Future<void> refresh() async {
      ref.invalidate(requestsProvider(scope));
      ref.invalidate(hrRecordsProvider((scope, 'announcement')));
      await controller.load();
    }

    if (filter == InboxFilter.requests) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: Space.page,
          children: [_ProfileRequests(scope: scope, canApprove: canApprove)],
        ),
      );
    }
    if (filter == InboxFilter.announcements) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: Space.page,
          children: [_Announcements(scope: scope)],
        ),
      );
    }
    if (!ops.loaded) {
      if (ops.error != null) {
        return ListView(
          padding: Space.page,
          children: [InlineError(ops.error!, retry: controller.load)],
        );
      }
      return ListView(
        padding: Space.page,
        children: const [LoadingState(rows: 5, rowHeight: 60, header: false)],
      );
    }
    final rows = ops.inbox
        .where((n) => filter != InboxFilter.unread || n['read_at'] == null)
        .toList();
    return RefreshIndicator(
      onRefresh: refresh,
      child: rows.isEmpty
          ? ListView(
              padding: Space.page,
              children: [
                EmptyState(
                  title: filter == InboxFilter.unread
                      ? tr('You are all caught up', 'सब पढ़ लिया')
                      : tr('No messages yet', 'अभी कोई संदेश नहीं'),
                  message: tr(
                    'Decisions, alerts and announcements for this site will appear here.',
                    'इस साइट के निर्णय, सूचनाएँ और घोषणाएँ यहाँ दिखेंगी।',
                  ),
                  illustration: TinyKind.envelope,
                ),
              ],
            )
          : ListView.builder(
              padding: Space.page,
              itemCount: rows.length,
              itemBuilder: (context, i) => MessageRow(
                item: Json.from(rows[i]),
                divider: i < rows.length - 1,
              ),
            ),
    );
  }
}

class MessageRow extends StatelessWidget {
  const MessageRow({super.key, required this.item, this.divider = true});
  final Json item;
  final bool divider;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final unread = item['read_at'] == null;
    final type = '${item['event_type']}';
    return Column(
      children: [
        InkWell(
          onTap: () => context.go('/inbox/${item['id']}'),
          borderRadius: BorderRadius.circular(Radii.s),
          child: Semantics(
            label: unread ? tr('Unread', 'अपठित') : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: unread ? t.accentPale : t.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppIcon(eventIcon(type), size: 20, color: t.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventTitle(type),
                          style: text.bodyLarge?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${relativeTime(context, item['created_at'])} · ${moduleLabel('${item['module']}')}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (unread)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 8),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: t.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.text, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (divider) const Divider(),
      ],
    );
  }
}

String moduleLabel(String module) => tr(
  const {
        'tasks': 'Tasks',
        'leave': 'Leave',
        'my_attendance': 'Attendance',
        'attendance': 'Attendance',
        'field_duty': 'Field duty',
        'my_dwr': 'Daily report',
        'dwr_review': 'Team reports',
        'my_payroll': 'Payslips',
        'payroll': 'Payroll',
        'expenses': 'Expenses',
        'assets': 'Assets',
        'helpdesk': 'Helpdesk',
        'grievances': 'Grievance',
        'my_documents': 'Documents',
        'announcements': 'Announcements',
        'my_hr': 'HR information',
      }[module] ??
      module.replaceAll('_', ' '),
  const {
        'tasks': 'कार्य',
        'leave': 'छुट्टी',
        'my_attendance': 'उपस्थिति',
        'attendance': 'उपस्थिति',
        'field_duty': 'फील्ड ड्यूटी',
        'my_dwr': 'दैनिक रिपोर्ट',
        'dwr_review': 'टीम रिपोर्ट',
        'my_payroll': 'वेतन पर्ची',
        'payroll': 'वेतन',
        'expenses': 'व्यय',
        'assets': 'उपकरण',
        'helpdesk': 'सहायता',
        'grievances': 'शिकायत',
        'my_documents': 'दस्तावेज़',
        'announcements': 'घोषणाएँ',
        'my_hr': 'एचआर जानकारी',
      }[module] ??
      module,
);

String eventDescription(String type) {
  if (type.contains('reminder')) {
    return tr(
      'Submit your daily report when it is ready. Nothing is sent automatically.',
      'तैयार होने पर अपनी दैनिक रिपोर्ट भेजें। कुछ भी अपने आप नहीं भेजा जाता।',
    );
  }
  // Event types carry suffixes (versions, ids, dates): match the first two parts.
  final parts = type.split('.');
  final key = parts.length > 2 && parts[1] != 'group'
      ? parts.take(2).join('.')
      : type;
  return switch (key) {
    'attendance.accepted' => tr(
      'Your attendance evidence was accepted under the site policy.',
      'साइट नीति के तहत आपकी उपस्थिति साक्ष्य स्वीकार हुआ।',
    ),
    'attendance.pending_verification' || 'attendance.review_required' => tr(
      'An attendance event needs an independent review before it counts.',
      'एक उपस्थिति घटना को गिने जाने से पहले स्वतंत्र समीक्षा चाहिए।',
    ),
    'event.reviewed' => tr(
      'A reviewer decided on your attendance evidence. Open attendance to see the result.',
      'समीक्षक ने आपकी उपस्थिति पर निर्णय लिया। परिणाम देखने के लिए उपस्थिति खोलें।',
    ),
    'task.assigned' => tr(
      'A new task is waiting in your task list.',
      'आपकी कार्य सूची में नया कार्य है।',
    ),
    'task.updated' => tr(
      'The status or details of one of your tasks changed.',
      'आपके किसी कार्य की स्थिति या विवरण बदला।',
    ),
    'task.comment' || 'task.commented' => tr(
      'Someone commented on a task assigned to you.',
      'आपको सौंपे कार्य पर किसी ने टिप्पणी की।',
    ),
    'leave.requested' => tr(
      'A leave request was received and is waiting for a decision.',
      'छुट्टी अनुरोध प्राप्त हुआ और निर्णय लंबित है।',
    ),
    'leave.decided' => tr(
      'A decision was made on a leave request.',
      'छुट्टी अनुरोध पर निर्णय हुआ।',
    ),
    'visit.assigned' => tr(
      'A field visit was scheduled for you.',
      'आपके लिए फील्ड दौरा निर्धारित हुआ।',
    ),
    'dwr.submitted' => tr(
      'A team member sent a daily report for your review.',
      'टीम सदस्य ने समीक्षा के लिए दैनिक रिपोर्ट भेजी।',
    ),
    'dwr.approve' => tr(
      'Your daily report was approved.',
      'आपकी दैनिक रिपोर्ट स्वीकृत हुई।',
    ),
    'dwr.return' => tr(
      'Your daily report was returned for changes. Open it to update and resubmit.',
      'आपकी दैनिक रिपोर्ट बदलाव के लिए लौटाई गई। खोलकर सुधारें और फिर भेजें।',
    ),
    'dwr.prepared' => tr(
      'Your DWR agent prepared today\'s report from your chat. Review it and submit.',
      'आपके DWR एजेंट ने आपकी चैट से आज की रिपोर्ट तैयार की। जाँचकर भेजें।',
    ),
    'dwr.group.added' => tr(
      'Post your daily work in the group; your DWR is prepared from your messages.',
      'समूह में अपना दैनिक काम लिखें; आपकी DWR आपके संदेशों से तैयार होगी।',
    ),
    'payroll.published' => tr(
      'A published payslip is available under Me › Payslips.',
      'प्रकाशित वेतन पर्ची Me › वेतन पर्ची में उपलब्ध है।',
    ),
    'payroll.paid' => tr(
      'The payroll team recorded a salary payment. See Me › Payslips for the reference.',
      'पेरोल टीम ने वेतन भुगतान दर्ज किया। संदर्भ के लिए Me › वेतन पर्ची देखें।',
    ),
    _ => tr(
      'Open the related page for details.',
      'विवरण के लिए संबंधित पृष्ठ खोलें।',
    ),
  };
}

class MessageDetailPage extends ConsumerStatefulWidget {
  const MessageDetailPage({super.key, required this.scope, required this.id});
  final SiteScope scope;
  final String id;
  @override
  ConsumerState<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends ConsumerState<MessageDetailPage> {
  bool marked = false;
  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(operationsProvider(widget.scope));
    final controller = ref.read(operationsProvider(widget.scope).notifier);
    final item = ops.inbox.where((n) => '${n['id']}' == widget.id).firstOrNull;
    if (item != null && item['read_at'] == null && !marked && !ops.offline) {
      marked = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.markRead(widget.id),
      );
    }
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return PageScaffold(
      title: tr('Message', 'संदेश'),
      body: !ops.loaded
          ? ListView(
              padding: Space.page,
              children: const [LoadingState(rows: 2)],
            )
          : item == null
          ? ListView(
              padding: Space.page,
              children: [
                EmptyState(
                  title: tr('Message unavailable', 'संदेश उपलब्ध नहीं'),
                  message: tr(
                    'It may belong to another site or was removed.',
                    'यह दूसरी साइट का हो सकता है या हटा दिया गया।',
                  ),
                  illustration: TinyKind.envelope,
                ),
              ],
            )
          : ListView(
              padding: Space.page,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: t.accentPale,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: AppIcon(
                        eventIcon('${item['event_type']}'),
                        color: t.text,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventTitle('${item['event_type']}'),
                            style: text.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatInstant(context, item['created_at'])} · ${moduleLabel('${item['module']}')}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(tr('What happened', 'क्या हुआ'), style: text.titleSmall),
                const SizedBox(height: 6),
                Text(
                  eventDescription('${item['event_type']}'),
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 24),
                ActionButton(
                  tr(
                    'Open ${moduleLabel('${item['module']}')}',
                    '${moduleLabel('${item['module']}')} खोलें',
                  ),
                  icon: AppIcons.arrowRight,
                  onPressed: () => context.go(routeForNotification(item)),
                ),
                if (item['push_status'] != null &&
                    '${item['push_status']}' != 'delivered') ...[
                  const SizedBox(height: 16),
                  Text(
                    tr(
                      'Push delivery is best effort. This inbox is the reliable record.',
                      'पुश डिलीवरी सर्वोत्तम प्रयास है। यह इनबॉक्स विश्वसनीय रिकॉर्ड है।',
                    ),
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ProfileRequests extends ConsumerWidget {
  const _ProfileRequests({required this.scope, required this.canApprove});
  final SiteScope scope;
  final bool canApprove;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(requestsProvider(scope))
      .when(
        loading: () => const LoadingState(rows: 3, header: false),
        error: (e, _) => InlineError(
          e,
          retry: () => ref.invalidate(requestsProvider(scope)),
        ),
        data: (d) {
          if (d.profileRequests.isEmpty) {
            return EmptyState(
              title: tr('No requests', 'कोई अनुरोध नहीं'),
              message: tr(
                'Profile update requests and their decisions appear here.',
                'प्रोफ़ाइल अपडेट अनुरोध और उनके निर्णय यहाँ दिखेंगे।',
              ),
              illustration: TinyKind.clipboard,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                tr('Profile update requests', 'प्रोफ़ाइल अपडेट अनुरोध'),
                top: 4,
                subtitle: tr(
                  'Contact changes reviewed by HR',
                  'एचआर द्वारा समीक्षित संपर्क बदलाव',
                ),
              ),
              for (final (i, r) in d.profileRequests.indexed) ...[
                _RequestCard(scope: scope, request: r, canApprove: canApprove),
                if (i < d.profileRequests.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          );
        },
      );
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({
    required this.scope,
    required this.request,
    required this.canApprove,
  });
  final SiteScope scope;
  final Query$ProfileRequests$profileRequests request;
  final bool canApprove;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final text = Theme.of(context).textTheme;
    // Pending requests show current → proposed; decided ones show the proposal.
    final pending = r.status == 'pending';
    final proposed = personalEntries(r.details),
        current = personalEntries(r.currentDetails);
    final changes = [
      if (!pending || r.currentPhone != r.phone)
        (tr('Phone number', 'फ़ोन नंबर'), r.currentPhone, r.phone),
      if (r.details != null)
        for (final (i, e) in proposed.indexed)
          if (e.$3 != current[i].$3 && (pending || e.$3 != null))
            (e.$2, current[i].$3, e.$3),
    ];
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.isSelf
                      ? tr('Your profile update', 'आपका प्रोफ़ाइल अपडेट')
                      : r.employeeName,
                  style: text.titleMedium,
                ),
              ),
              StatusPill.status(r.status),
            ],
          ),
          if (r.hasPhoto) ...[
            const SizedBox(height: 10),
            Avatar(
              r.employeeName,
              size: 72,
              photo: ref
                  .watch(photoProvider((scope, 'request/${r.id}', r.id)))
                  .value,
            ),
          ],
          const SizedBox(height: 6),
          for (final (label, before, after) in changes)
            KeyValueRow(
              label,
              pending && before != null && before.isNotEmpty
                  ? '$before → ${after ?? '—'}'
                  : after ?? '—',
            ),
          Text(r.reason, style: text.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatInstant(context, r.createdAt),
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
          if (r.reviewNote != null) ...[
            const SizedBox(height: 8),
            NoticeBanner(
              '${tr('HR note', 'एचआर टिप्पणी')}: ${r.reviewNote}',
              tone: r.status == 'approved'
                  ? StatusTone.success
                  : r.status == 'rejected'
                  ? StatusTone.error
                  : StatusTone.info,
              icon: AppIcons.messageSquareText,
            ),
          ],
          if (canApprove && !r.isSelf && r.status == 'pending') ...[
            const SizedBox(height: 10),
            ActionButton(
              tr('Review request', 'अनुरोध की समीक्षा'),
              icon: AppIcons.messageSquareMore,
              variant: ButtonVariant.secondary,
              onPressed: () => _review(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context, WidgetRef ref) async {
    final result = await askDecision(
      context,
      title: tr('Review profile update', 'प्रोफ़ाइल अपडेट समीक्षा'),
      message: request.employeeName,
    );
    if (result == null) return;
    try {
      await ref
          .read(apiProvider)
          .foundationWrite(
            scope,
            'review_profile',
            Input$FoundationInput(
              id: request.id,
              expectedVersion: request.version,
              approve: result.approve,
              note: result.note,
            ),
          );
      ref.invalidate(requestsProvider(scope));
      if (context.mounted) {
        showConfirmation(
          context,
          result.approve
              ? tr('Request approved', 'अनुरोध स्वीकृत')
              : tr('Request rejected', 'अनुरोध अस्वीकृत'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}

class _Announcements extends ConsumerWidget {
  const _Announcements({required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(hrRecordsProvider((scope, 'announcement')))
      .when(
        loading: () => const LoadingState(rows: 3, header: false),
        error: (e, _) => InlineError(
          e,
          retry: () =>
              ref.invalidate(hrRecordsProvider((scope, 'announcement'))),
        ),
        data: (d) {
          final rows = (d['records'] as List? ?? [])
              .where((r) => r['status'] == 'published')
              .toList();
          if (rows.isEmpty) {
            return EmptyState(
              title: tr('No announcements', 'कोई घोषणा नहीं'),
              message: tr(
                'Published announcements for your audience appear here.',
                'आपके लिए प्रकाशित घोषणाएँ यहाँ दिखेंगी।',
              ),
              illustration: TinyKind.envelope,
            );
          }
          return Column(
            children: [
              for (final (i, r) in rows.indexed)
                ActionRow(
                  icon: AppIcons.megaphone,
                  title:
                      '${r['payload']?['title'] ?? tr('Announcement', 'घोषणा')}',
                  subtitle: r['payload']?['expiresOn'] != null
                      ? tr(
                          'Until ${formatDay(context, r['payload']['expiresOn'])}',
                          '${formatDay(context, r['payload']['expiresOn'])} तक',
                        )
                      : formatInstant(
                          context,
                          r['updated_at'] ?? r['created_at'],
                        ),
                  trailing: r['acknowledged'] == true
                      ? StatusPill(
                          tr('Acknowledged', 'स्वीकार किया'),
                          tone: StatusTone.success,
                          icon: AppIcons.check,
                        )
                      : null,
                  divider: i < rows.length - 1,
                  onTap: () =>
                      context.go(recordRoute('announcement', '${r['id']}')),
                ),
            ],
          );
        },
      );
}
