import 'ui/icons.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import 'providers.dart';
import 'scope.dart';
import 'mobile_ui.dart';
import 'payslip_pdf.dart';
import 'ui/components.dart';
import 'workspace.dart';
import 'graphql/operations.graphql.dart';

typedef HrMap = Map<String, dynamic>;
String paiseText(dynamic value) {
  final v = BigInt.parse(value.toString());
  return '${v ~/ BigInt.from(100)}.${(v % BigInt.from(100)).toString().padLeft(2, '0')}';
}

const hrNames = {
  'payroll': ['Payslips', 'वेतन पर्ची'],
  'expense': ['Expenses', 'व्यय'],
  'asset': ['My Assets', 'मेरे उपकरण'],
  'helpdesk': ['Helpdesk', 'सहायता'],
  'grievance': ['Confidential grievance', 'गोपनीय शिकायत'],
  'document': ['Documents', 'दस्तावेज़'],
  'policy': ['Policies', 'नीतियाँ'],
  'announcement': ['Announcements', 'घोषणाएँ'],
  'lifecycle': ['Employment history', 'रोजगार इतिहास'],
};
const hrModules = {
  'payroll': 'my_payroll',
  'expense': 'expenses',
  'asset': 'assets',
  'helpdesk': 'helpdesk',
  'grievance': 'grievances',
  'document': 'my_documents',
  'policy': 'my_documents',
  'announcement': 'announcements',
  'lifecycle': 'my_hr',
};

String hrFieldLabel(String key) {
  const labels = <String, List<String>>{
    'amountPaise': ['Amount', 'राशि'],
    'date': ['Expense date', 'व्यय की तारीख'],
    'category': ['Category', 'श्रेणी'],
    'description': ['Description', 'विवरण'],
    'subject': ['Subject', 'विषय'],
    'assetTag': ['Asset tag', 'उपकरण क्रमांक'],
    'name': ['Name', 'नाम'],
    'serialNumber': ['Serial number', 'सीरियल नंबर'],
    'condition': ['Condition', 'स्थिति'],
    'title': ['Title', 'शीर्षक'],
    'expiresOn': ['Expiry date', 'समाप्ति की तारीख'],
    'effectiveOn': ['Effective date', 'प्रभावी तारीख'],
    'body': ['Details', 'विवरण'],
    'event': ['Employment event', 'रोजगार घटना'],
    'employmentId': ['Employment record', 'रोजगार रिकॉर्ड'],
    'destinationSiteId': ['Destination site', 'नई साइट'],
    'designation': ['Designation', 'पद'],
    'department': ['Department', 'विभाग'],
    'salaryStructureId': ['Salary structure', 'वेतन संरचना'],
    'details': ['Reason and details', 'कारण और विवरण'],
    'acknowledgment': ['Acknowledgment required', 'पुष्टि आवश्यक'],
  };
  final l = labels[key];
  return l == null ? key : tr(l[0], l[1]);
}

/// Plain labels for backend workflow verbs.
String actionLabel(String kind, String action) => tr(
  switch (action) {
    'submit' => 'Send to HR',
    'approve' => 'Approve',
    'reject' => 'Reject',
    'settle' => 'Mark as settled',
    'assign' => 'Assign to employee',
    'acknowledge' => kind == 'asset' ? 'Acknowledge receipt' : 'Acknowledge',
    'return' => 'Request return',
    'receive' => 'Mark received',
    'clear' => 'Clear asset',
    'start' => 'Start working on it',
    'resolve' => 'Mark resolved',
    'close' => 'Close request',
    'comment' => 'Add comment',
    'publish' => 'Publish',
    'validate' => 'Validate',
    'review' => 'Mark reviewed',
    _ => action,
  },
  switch (action) {
    'submit' => 'एचआर को भेजें',
    'approve' => 'स्वीकृत करें',
    'reject' => 'अस्वीकार करें',
    'settle' => 'निपटाया चिह्नित करें',
    'assign' => 'कर्मचारी को सौंपें',
    'acknowledge' => 'स्वीकार करें',
    'return' => 'वापसी अनुरोध',
    'receive' => 'प्राप्त चिह्नित करें',
    'clear' => 'उपकरण क्लियर करें',
    'start' => 'काम शुरू करें',
    'resolve' => 'हल चिह्नित करें',
    'close' => 'अनुरोध बंद करें',
    'comment' => 'टिप्पणी जोड़ें',
    'publish' => 'प्रकाशित करें',
    'validate' => 'जाँचें',
    'review' => 'समीक्षित चिह्नित करें',
    _ => action,
  },
);

String historyEventLabel(String event) => tr(
  const {
        'save': 'Saved',
        'submit': 'Sent to HR',
        'approve': 'Approved',
        'reject': 'Rejected',
        'settle': 'Settled',
        'assign': 'Assigned',
        'acknowledge': 'Acknowledged',
        'return': 'Return requested',
        'receive': 'Received',
        'clear': 'Cleared',
        'start': 'Started',
        'resolve': 'Resolved',
        'close': 'Closed',
        'comment': 'Comment',
        'publish': 'Published',
        'validate': 'Validated',
        'review': 'Reviewed',
        'create': 'Created',
        'edit': 'Edited',
      }[event] ??
      event,
  const {
        'save': 'सहेजा',
        'submit': 'एचआर को भेजा',
        'approve': 'स्वीकृत',
        'reject': 'अस्वीकृत',
        'settle': 'निपटाया',
        'assign': 'सौंपा',
        'acknowledge': 'स्वीकार किया',
        'return': 'वापसी अनुरोध',
        'receive': 'प्राप्त',
        'clear': 'क्लियर',
        'start': 'शुरू',
        'resolve': 'हल',
        'close': 'बंद',
        'comment': 'टिप्पणी',
        'publish': 'प्रकाशित',
        'validate': 'जाँचा',
        'review': 'समीक्षित',
        'create': 'बनाया',
        'edit': 'बदला',
      }[event] ??
      event,
);

final hrQueueProvider = FutureProvider.autoDispose.family<HrMap, SiteScope>(
  (ref, scope) async => HrMap.from(
    (await ref
        .watch(apiProvider)
        .scopedRead(scope, documentNodeQueryApprovalQueue))['approvalQueue'],
  ),
);

/// Records of one kind (or payroll results) for a scope. Sensitive data lives
/// only in memory and is dropped when nothing watches it.
final hrRecordsProvider = FutureProvider.autoDispose
    .family<HrMap, (SiteScope, String)>((ref, key) async {
      final (scope, kind) = key;
      final payroll = kind == 'payroll';
      final api = ref.watch(apiProvider);
      await api.capabilities(scope);
      final response = await api.scopedRead(
        scope,
        payroll ? documentNodeQueryPayroll : documentNodeQueryHrRecords,
        payroll ? {} : {'kind': kind},
      );
      return HrMap.from(response[payroll ? 'payroll' : 'hrRecords']);
    });

String hrTitle(String kind) =>
    tr(hrNames[kind]?[0] ?? kind, hrNames[kind]?[1] ?? kind);

String recordTitle(String kind, HrMap r) {
  final p = r['payload'] as Map? ?? const {};
  return '${p['title'] ?? p['subject'] ?? p['name'] ?? (p['event'] == null ? null : '${p['event']}'.replaceAll('_', ' ')) ?? p['category'] ?? tr('Record', 'रिकॉर्ड')}';
}

IconData kindIcon(String kind) => switch (kind) {
  'payroll' => AppIcons.receiptText,
  'expense' => AppIcons.walletCards,
  'asset' => AppIcons.monitorSmartphone,
  'helpdesk' => AppIcons.headset,
  'grievance' => AppIcons.lockKeyhole,
  'document' => AppIcons.fileText,
  'policy' => AppIcons.bookOpenCheck,
  'announcement' => AppIcons.megaphone,
  'lifecycle' => AppIcons.history,
  _ => AppIcons.folderOpen,
};

/// Hides sensitive content while the app is in the background and reloads on
/// resume, so payslips never show in the task switcher.
class PrivacyShield extends StatefulWidget {
  const PrivacyShield({super.key, required this.child, this.onResume});
  final Widget child;
  final VoidCallback? onResume;
  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield>
    with WidgetsBindingObserver {
  bool hidden = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (hidden) setState(() => hidden = false);
      widget.onResume?.call();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!hidden) setState(() => hidden = true);
    }
  }

  @override
  Widget build(BuildContext context) =>
      hidden ? const SizedBox.expand() : widget.child;
}

class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key, required this.scope, required this.kind});
  final SiteScope scope;
  final String kind;
  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  bool showAmounts = false;
  late final poller = VisiblePoller(
    const Duration(seconds: 30),
    () async => ref.invalidate(hrRecordsProvider((widget.scope, widget.kind))),
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

  bool get payroll => widget.kind == 'payroll';
  String get base =>
      GoRouterState.of(context).uri.path.startsWith('/me') ? '/me' : '/work';

  @override
  Widget build(BuildContext context) {
    final key = (widget.scope, widget.kind);
    final data = ref.watch(hrRecordsProvider(key));
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: hrTitle(widget.kind),
      actions: [
        if (payroll)
          IconButton(
            tooltip: showAmounts
                ? tr('Hide amounts', 'राशि छिपाएँ')
                : tr('Show amounts', 'राशि दिखाएँ'),
            onPressed: () => setState(() => showAmounts = !showAmounts),
            icon: AppIcon(showAmounts ? AppIcons.eyeOff : AppIcons.eye),
          ),
      ],
      body: PrivacyShield(
        onResume: () => ref.invalidate(hrRecordsProvider(key)),
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(hrRecordsProvider(key)),
          child: data.when(
            loading: () => ListView(
              padding: Space.page,
              children: const [LoadingState(rows: 5, rowHeight: 64)],
            ),
            error: (e, _) => ListView(
              padding: Space.page,
              children: [
                InlineError(
                  e,
                  retry: () => ref.invalidate(hrRecordsProvider(key)),
                ),
              ],
            ),
            data: (d) {
              final rows =
                  ((d[payroll ? 'results' : 'records'] as List?) ?? const [])
                      .map((r) => HrMap.from(r as Map))
                      .toList();
              if (payroll) {
                rows.sort(
                  (a, b) =>
                      '${b['periodStart']}'.compareTo('${a['periodStart']}'),
                );
              }
              return ListView(
                padding: Space.page,
                children: [
                  if (widget.kind == 'grievance')
                    NoticeBanner(
                      tr(
                        'Only you and assigned confidential handlers can see your case.',
                        'केवल आप और नियुक्त गोपनीय अधिकारी मामला देख सकते हैं।',
                      ),
                      icon: AppIcons.lockKeyhole,
                    ),
                  if (!payroll && d['canCreate'] == true) ...[
                    ActionButton(
                      _createLabel(widget.kind),
                      icon: AppIcons.plus,
                      onPressed: () => context.go(
                        '$base/records/${widget.kind}/edit',
                        extra: RecordEditorArgs(data: d),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (rows.isEmpty)
                    EmptyState(
                      title: payroll
                          ? tr(
                              'No published payslips yet',
                              'अभी कोई प्रकाशित वेतन पर्ची नहीं',
                            )
                          : tr('Nothing here yet', 'अभी कुछ नहीं'),
                      message: payroll
                          ? tr(
                              'Payslips appear here after payroll is published for you.',
                              'वेतन प्रकाशित होने पर पर्चियाँ यहाँ दिखेंगी।',
                            )
                          : tr(
                              'Records you create or that are shared with you appear here.',
                              'आपके बनाए या साझा किए रिकॉर्ड यहाँ दिखेंगे।',
                            ),
                      illustration: payroll
                          ? TinyKind.receipt
                          : TinyKind.clipboard,
                    ),
                  if (payroll) ..._payrollRows(context, rows),
                  if (!payroll)
                    for (final (i, r) in rows.indexed)
                      _RecordRow(
                            kind: widget.kind,
                            record: r,
                            divider: i < rows.length - 1,
                            onTap: () => context.go(
                              '$base/records/${widget.kind}/${r['id']}',
                            ),
                          ),
                  if (payroll &&
                      rows.every((r) => r['isSelf'] == true) &&
                      (d['structures'] as List? ?? const []).isNotEmpty) ...[
                    SectionHeader(tr('Salary history', 'वेतन इतिहास')),
                    for (final (i, st) in (d['structures'] as List).indexed)
                      ActionRow(
                        icon: AppIcons.route,
                        title:
                            '${formatDay(context, st['startsOn'])} – ${st['endsOn'] == null ? tr('Current', 'वर्तमान') : formatDay(context, st['endsOn'])}',
                        subtitle:
                            '${showAmounts ? formatInr(st['components']?['netPaise']) : '••••••'} · ${st['reason'] ?? ''}',
                        divider: i < (d['structures'] as List).length - 1,
                      ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    tr(
                      'Online only. Sensitive records are never stored in the offline outbox.',
                      'केवल ऑनलाइन। संवेदनशील रिकॉर्ड ऑफ़लाइन आउटबॉक्स में संग्रहित नहीं होते।',
                    ),
                    style: text.bodySmall,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

extension on _RecordsPageState {
  /// Own payslips first; payroll staff also see the site's results, named.
  List<Widget> _payrollRows(BuildContext context, List<HrMap> rows) {
    final mine = rows.where((r) => r['isSelf'] == true).toList(),
        team = rows.where((r) => r['isSelf'] != true).toList();
    Widget row(HrMap r, bool last, {bool named = false}) => ActionRow(
      icon: AppIcons.receiptText,
      title: named
          ? '${r['snapshot']?['employeeName']} · ${formatMonth(context, r['periodStart'])}'
          : formatMonth(context, r['periodStart']),
      subtitle:
          '${named ? '${r['snapshot']?['employeeCode']} · ' : ''}${formatDayShort(context, r['periodStart'])} – ${formatDayShort(context, r['periodEnd'])}${showAmounts ? ' · ${tr('Net', 'शुद्ध')} ${formatInr(r['snapshot']?['netPaise'])}' : ''}',
      trailing: paymentPill(r) ?? StatusPill.status('${r['status']}'),
      divider: !last,
      onTap: () => context.go('$base/records/payroll/${r['id']}'),
    );
    if (team.isEmpty) {
      return [for (final (i, r) in mine.indexed) row(r, i == mine.length - 1)];
    }
    return [
      SectionHeader(tr('My payslips', 'मेरी वेतन पर्चियाँ'), top: 4),
      if (mine.isEmpty)
        Text(
          tr(
            'No published payslips for you yet.',
            'आपकी कोई प्रकाशित वेतन पर्ची अभी नहीं है।',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      for (final (i, r) in mine.indexed) row(r, i == mine.length - 1),
      SectionHeader('${tr('Team payroll', 'टीम वेतन')} · ${team.length}'),
      for (final (i, r) in team.indexed)
        row(r, i == team.length - 1, named: true),
    ];
  }
}

String _createLabel(String kind) => switch (kind) {
  'expense' => tr('New expense claim', 'नया व्यय दावा'),
  'helpdesk' => tr('New helpdesk request', 'नया सहायता अनुरोध'),
  'grievance' => tr(
    'Raise a confidential grievance',
    'गोपनीय शिकायत दर्ज करें',
  ),
  'document' => tr('Add a document', 'दस्तावेज़ जोड़ें'),
  'asset' => tr('Register an asset', 'उपकरण पंजीकृत करें'),
  'policy' => tr('New policy draft', 'नई नीति ड्राफ़्ट'),
  'announcement' => tr('New announcement', 'नई घोषणा'),
  'lifecycle' => tr('New employment event', 'नई रोजगार घटना'),
  _ => tr('New draft', 'नया ड्राफ़्ट'),
};

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.kind,
    required this.record,
    required this.divider,
    required this.onTap,
  });
  final String kind;
  final HrMap record;
  final bool divider;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = record['payload'] as Map? ?? const {};
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    String? line;
    Widget? extra;
    switch (kind) {
      case 'expense':
        line = [
          if (p['date'] != null) formatDay(context, p['date']),
          if (p['category'] != null) '${p['category']}',
        ].join(' · ');
        extra = Text(formatInr(p['amountPaise'] ?? 0), style: text.titleMedium);
      case 'document':
        final exp = DateTime.tryParse('${p['expiresOn'] ?? ''}');
        line =
            '${p['category'] ?? ''}${exp == null ? '' : ' · ${tr('Expires', 'समाप्ति')} ${formatDay(context, p['expiresOn'])}'}';
        if (exp != null) {
          final days = exp.difference(DateTime.now()).inDays;
          if (days < 0) {
            extra = StatusPill(
              tr('Expired', 'समाप्त'),
              tone: StatusTone.error,
              icon: AppIcons.calendarX2,
            );
          } else if (days <= 30) {
            extra = StatusPill(
              tr('Expires in $days d', '$days दिन में समाप्त'),
              tone: StatusTone.warning,
              icon: AppIcons.calendarDays,
            );
          }
        }
      case 'policy':
      case 'announcement':
        line = p['effectiveOn'] != null
            ? '${tr('Effective', 'प्रभावी')} ${formatDay(context, p['effectiveOn'])}'
            : p['expiresOn'] != null
            ? '${tr('Until', 'तक')} ${formatDay(context, p['expiresOn'])}'
            : null;
        if (record['acknowledged'] == true) {
          extra = StatusPill(
            tr('Acknowledged', 'स्वीकार किया'),
            tone: StatusTone.success,
            icon: AppIcons.check,
          );
        }
      case 'lifecycle':
        line = p['effectiveOn'] != null
            ? formatDay(context, p['effectiveOn'])
            : null;
      case 'asset':
        line = [
          if (p['assetTag'] != null) '${p['assetTag']}',
          if (p['serialNumber'] != null) '${p['serialNumber']}',
        ].join(' · ');
      default:
        line = [
          if (p['category'] != null) '${p['category']}',
          formatInstant(context, record['updated_at'] ?? record['created_at']),
        ].join(' · ');
    }
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.s),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: t.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppIcon(kindIcon(kind), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recordTitle(kind, record),
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (line != null && line.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(line, style: text.bodySmall),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusPill.status('${record['status']}'),
                          if (extra != null && extra is StatusPill) extra,
                        ],
                      ),
                    ],
                  ),
                ),
                if (extra != null && extra is! StatusPill)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: extra,
                  ),
                const SizedBox(width: 4),
                AppIcon(AppIcons.chevronRight, color: t.textSecondary),
              ],
            ),
          ),
        ),
        if (divider) const Divider(),
      ],
    );
  }
}

class RecordDetailPage extends ConsumerStatefulWidget {
  const RecordDetailPage({
    super.key,
    required this.scope,
    required this.kind,
    required this.id,
  });
  final SiteScope scope;
  final String kind, id;
  @override
  ConsumerState<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends ConsumerState<RecordDetailPage> {
  bool busy = false, showNet = false;
  Object? error;
  bool get payroll => widget.kind == 'payroll';
  (SiteScope, String) get key => (widget.scope, widget.kind);
  String get base =>
      GoRouterState.of(context).uri.path.startsWith('/me') ? '/me' : '/work';

  List<String> actions(HrMap r) {
    final caps = List<String>.from(r['actions'] ?? const []),
        own = r['isSelf'] == true,
        s = r['status'];
    if (payroll) {
      return [
        for (final row in [
          ['draft', 'validate', 'edit'],
          ['validated', 'review', 'review'],
          ['reviewed', 'approve', 'approve'],
          ['approved', 'publish', 'manage'],
        ])
          if (row[0] == s && caps.contains(row[2])) row[1],
      ];
    }
    final result = <String>[];
    if (s == 'draft' && caps.contains('submit')) result.add('submit');
    if (s == 'submitted' && !own && caps.contains('approve')) {
      result.addAll(
        ['policy', 'announcement'].contains(widget.kind)
            ? ['publish']
            : ['approve', 'reject'],
      );
    }
    if (widget.kind == 'expense' &&
        s == 'approved' &&
        !own &&
        caps.contains('approve')) {
      result.add('settle');
    }
    if (widget.kind == 'asset') {
      if (['available', 'returned'].contains(s) && caps.contains('manage')) {
        result.add('assign');
      }
      if (own && s == 'assigned') result.add('acknowledge');
      if (own && ['assigned', 'acknowledged'].contains(s)) result.add('return');
      if (s == 'return_requested' && caps.contains('manage')) {
        result.add('receive');
      }
      if (s == 'returned' && caps.contains('manage')) result.add('clear');
    }
    if (['helpdesk', 'grievance'].contains(widget.kind)) {
      if (s == 'submitted' && caps.contains('review')) result.add('start');
      if (s == 'in_progress' && caps.contains('review')) result.add('resolve');
      if (s == 'resolved' && own) result.add('close');
      if (['submitted', 'in_progress'].contains(s)) result.add('comment');
    }
    if (s == 'published' &&
        caps.contains('submit') &&
        r['acknowledged'] != true) {
      result.add('acknowledge');
    }
    return result;
  }

  Future<void> command(String action, HrMap r, HrMap data) async {
    String? employee;
    final employees = (data['employees'] as List? ?? const []);
    final result = await askDecision(
      context,
      title: actionLabel(widget.kind, action),
      message: recordTitle(widget.kind, r),
      decision: false,
      approveLabel: actionLabel(widget.kind, action),
      extra: action == 'assign'
          ? StatefulBuilder(
              builder: (ctx, set) => DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr('Employee', 'कर्मचारी'),
                ),
                items: [
                  for (final e in employees)
                    DropdownMenuItem(
                      value: e['id'] as String,
                      child: Text(
                        '${e['name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => set(() => employee = v),
              ),
            )
          : null,
    );
    if (result == null) return;
    if (action == 'assign' && employee == null) {
      setState(
        () => error = StateError(
          tr(
            'Choose an employee to assign to.',
            'सौंपने के लिए कर्मचारी चुनें।',
          ),
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).scopedWrite(
        widget.scope,
        payroll
            ? documentNodeMutationPayrollCommand
            : documentNodeMutationHrCommand,
        {
          'operation': payroll ? action : 'action',
          'input': {
            'id': r['id'],
            'expectedVersion': r['version'],
            'clientId': const Uuid().v4(),
            if (payroll) 'reason': result.note else 'note': result.note,
            if (!payroll) 'action': action,
            if (action == 'assign') 'employeeId': employee,
          },
        },
      );
      ref.invalidate(hrRecordsProvider(key));
      ref.invalidate(hrQueueProvider(widget.scope));
      if (mounted) {
        showConfirmation(
          context,
          '${actionLabel(widget.kind, action)} · ${tr('done', 'हो गया')}',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// The published payslip in the site's saved design (see payslip_pdf.dart).
  Future<Uint8List> payslipPdf(HrMap r) async {
    final api = ref.read(apiProvider), epoch = api.scopeEpoch.capture();
    final (response, designed) = await (
      api.dio.get(
        '/payroll/${r['id']}/json',
        queryParameters: {'siteId': widget.scope.siteId},
        options: api.sensitiveOptions(widget.scope),
      ),
      api.scopedRead(widget.scope, documentNodeQueryPayroll, {
        'input': {'design': true, 'first': 1},
      }),
    ).wait;
    if (!api.scopeEpoch.isCurrent(epoch)) throw StateError('Scope changed');
    return buildPayslipPdf(
      HrMap.from((designed['payroll'] as Map)['design']['design'] as Map),
      HrMap.from(response.data as Map),
    );
  }

  Future<void> viewPayslip(HrMap r) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await payslipPdf(r);
      if (!mounted) return;
      context.go(
        '$base/attachment/payslip-${r['id']}?type=application/pdf&title=${Uri.encodeComponent(tr('Payslip', 'वेतन पर्ची'))}',
        extra: bytes,
      );
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> downloadPayslip(HrMap r) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await payslipPdf(r);
      await Printing.layoutPdf(
        name: 'payslip.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(hrRecordsProvider(key));
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return PageScaffold(
      title: hrTitle(widget.kind),
      actions: [
        IconButton(
          tooltip: tr('Refresh', 'रिफ्रेश'),
          onPressed: busy ? null : () => ref.invalidate(hrRecordsProvider(key)),
          icon: const AppIcon(AppIcons.rotateCw),
        ),
      ],
      body: PrivacyShield(
        onResume: () => ref.invalidate(hrRecordsProvider(key)),
        child: data.when(
          loading: () => ListView(
            padding: Space.page,
            children: const [LoadingState(rows: 4)],
          ),
          error: (e, _) => ListView(
            padding: Space.page,
            children: [
              InlineError(
                e,
                retry: () => ref.invalidate(hrRecordsProvider(key)),
              ),
            ],
          ),
          data: (d) {
            final rows =
                ((d[payroll ? 'results' : 'records'] as List?) ?? const [])
                    .map((x) => HrMap.from(x as Map))
                    .toList();
            final r = rows.where((x) => '${x['id']}' == widget.id).firstOrNull;
            if (r == null) {
              return ListView(
                padding: Space.page,
                children: [
                  EmptyState(
                    title: tr('Record unavailable', 'रिकॉर्ड उपलब्ध नहीं'),
                    message: tr(
                      'It may belong to another site or your access changed.',
                      'यह दूसरी साइट का हो सकता है या आपकी अनुमति बदली है।',
                    ),
                    illustration: TinyKind.lock,
                  ),
                ],
              );
            }
            final acts = actions(r);
            final history = (r['history'] as List? ?? const []);
            return ListView(
              padding: Space.page,
              children: [
                if (busy) const LinearProgressIndicator(),
                if (error != null) InlineError(error!),
                if (payroll)
                  ..._payrollDetail(context, r, t, text)
                else
                  ..._recordDetail(context, r, t, text),
                if (acts.isNotEmpty) ...[
                  SectionHeader(tr('Actions', 'क्रियाएँ')),
                  for (final a in acts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionButton(
                        actionLabel(widget.kind, a),
                        variant: ['reject'].contains(a)
                            ? ButtonVariant.danger
                            : a == acts.first
                            ? ButtonVariant.primary
                            : ButtonVariant.secondary,
                        onPressed: busy ? null : () => command(a, r, d),
                      ),
                    ),
                ],
                if (history.isNotEmpty) ...[
                  SectionHeader(tr('Decision history', 'निर्णय इतिहास')),
                  for (final (i, h) in history.indexed)
                    TimelineRow(
                      time: formatTime(context, h['created_at']),
                      title:
                          '${historyEventLabel('${h['event']}')} · v${h['version']}',
                      subtitle: '${h['note'] ?? h['reason'] ?? ''}'.isEmpty
                          ? formatDay(
                              context,
                              parseInstant(
                                h['created_at'],
                              )?.toIso8601String().substring(0, 10),
                            )
                          : '${h['note'] ?? h['reason']}',
                      kind:
                          [
                            'approve',
                            'publish',
                            'settle',
                            'resolve',
                            'close',
                            'clear',
                          ].contains(h['event'])
                          ? TimelineKind.done
                          : h['event'] == 'reject'
                          ? TimelineKind.end
                          : TimelineKind.neutral,
                      first: i == 0,
                      last: i == history.length - 1,
                    ),
                ],
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _payrollDetail(
    BuildContext context,
    HrMap r,
    AppTokens t,
    TextTheme text,
  ) {
    final s = HrMap.from(r['snapshot'] as Map);
    final lines = (s['lines'] as List? ?? const [])
        .map((l) => HrMap.from(l as Map))
        .toList();
    final earnings = lines
        .where((l) => !'${l['kind']}'.contains('deduct'))
        .toList();
    final deductions = lines
        .where((l) => '${l['kind']}'.contains('deduct'))
        .toList();
    final published =
        r['status'] == 'published' &&
        (r['actions'] as List? ?? const []).contains('export');
    final payments = (r['payments'] as List? ?? const [])
        .map((p) => HrMap.from(p as Map))
        .toList();
    return [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMonth(context, r['periodStart']),
                  style: text.headlineSmall,
                ),
                Text(
                  '${formatDay(context, r['periodStart'])} – ${formatDay(context, r['periodEnd'])} · ${s['employeeName']}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          paymentPill(r) ?? StatusPill.status('${r['status']}'),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: t.accentGradient,
          borderRadius: BorderRadius.circular(Radii.l),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Net pay', 'शुद्ध वेतन'),
                    style: text.labelMedium?.copyWith(color: t.onAccent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showNet ? formatInr(s['netPaise']) : '••••••',
                    style: text.headlineMedium?.copyWith(color: t.onAccent),
                    semanticsLabel: showNet ? null : tr('Hidden', 'छिपा हुआ'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: showNet
                  ? tr('Hide amount', 'राशि छिपाएँ')
                  : tr('Show amount', 'राशि दिखाएँ'),
              style: IconButton.styleFrom(
                foregroundColor: t.onAccent,
                minimumSize: const Size(48, 48),
              ),
              onPressed: () => setState(() => showNet = !showNet),
              icon: AppIcon(showNet ? AppIcons.eyeOff : AppIcons.eye),
            ),
          ],
        ),
      ),
      if (published) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                tr('View payslip', 'वेतन पर्ची देखें'),
                icon: AppIcons.fileDown,
                variant: ButtonVariant.secondary,
                onPressed: busy ? null : () => viewPayslip(r),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                tr('Download / print', 'डाउनलोड / प्रिंट'),
                icon: AppIcons.download,
                variant: ButtonVariant.secondary,
                onPressed: busy ? null : () => downloadPayslip(r),
              ),
            ),
          ],
        ),
      ],
      SectionHeader(tr('Payment', 'भुगतान')),
      if (payments.isEmpty)
        Text(
          tr(
            'No payment recorded for this pay period yet.',
            'इस वेतन अवधि का कोई भुगतान अभी दर्ज नहीं है।',
          ),
          style: text.bodySmall,
        ),
      for (final (i, p) in payments.indexed)
        ActionRow(
          icon: p['kind'] == 'reversal' ? AppIcons.undo2 : AppIcons.walletCards,
          title:
              '${p['kind'] == 'reversal' ? '−' : ''}${showNet ? formatInr(p['paise']) : '••••••'}${p['kind'] == 'reversal' ? ' · ${tr('Reversed', 'वापस लिया गया')}' : ''}',
          subtitle:
              '${formatDay(context, p['paidOn'])} · ${_methods[p['method']] ?? p['method']} · ${p['reference']}',
          divider: i < payments.length - 1,
        ),
      SectionHeader(tr('Earnings', 'आय')),
      for (final l in earnings) _LineRow(line: l, show: showNet),
      if (deductions.isNotEmpty) ...[
        SectionHeader(tr('Deductions', 'कटौतियाँ')),
        for (final l in deductions) _LineRow(line: l, show: showNet),
      ],
      ExpansionTile(
        title: Text(
          tr('How this was calculated', 'गणना कैसे हुई'),
          style: text.titleSmall,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${s['assumptions'] ?? ''}\n${s['attendanceNote'] ?? ''}\n${tr('Policy', 'नीति')} ${s['policyVersion'] ?? ''} · ${s['rounding'] ?? ''}'
                    .trim(),
                style: text.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      Text(
        tr(
          'Payments are recorded by the payroll team after they are made. Downloaded copies cannot be remotely revoked.',
          'भुगतान होने के बाद पेरोल टीम उन्हें दर्ज करती है। डाउनलोड की गई प्रतियाँ दूर से रद्द नहीं की जा सकतीं।',
        ),
        style: text.bodySmall,
      ),
    ];
  }

  List<Widget> _recordDetail(
    BuildContext context,
    HrMap r,
    AppTokens t,
    TextTheme text,
  ) {
    final p = r['payload'] as Map? ?? const {};
    final files = (r['files'] as List? ?? const []);
    final hiddenKeys = {
      'employmentId',
      'salaryStructureId',
      'destinationSiteId',
    };
    final headline = widget.kind == 'expense'
        ? formatInr(p['amountPaise'] ?? 0)
        : null;
    return [
      Text(recordTitle(widget.kind, r), style: text.headlineSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          StatusPill.status('${r['status']}'),
          if (r['acknowledged'] == true)
            StatusPill(
              tr('Acknowledged', 'स्वीकार किया'),
              tone: StatusTone.success,
              icon: AppIcons.check,
            ),
          if (widget.kind == 'grievance')
            StatusPill(
              tr('Confidential', 'गोपनीय'),
              tone: StatusTone.info,
              icon: AppIcons.lockKeyhole,
            ),
        ],
      ),
      if (headline != null) ...[
        const SizedBox(height: 14),
        Text(headline, style: text.displaySmall),
      ],
      if (r['status'] == 'draft' &&
          (r['actions'] as List? ?? const []).contains('edit')) ...[
        const SizedBox(height: 12),
        ActionButton(
          tr('Edit / attach', 'बदलें / संलग्न करें'),
          icon: AppIcons.pencil,
          variant: ButtonVariant.secondary,
          onPressed: () => context.go(
            '$base/records/${widget.kind}/edit',
            extra: RecordEditorArgs(
              data: HrMap.from(ref.read(hrRecordsProvider(key)).value ?? {}),
              initial: r,
            ),
          ),
        ),
      ],
      SectionHeader(tr('Details', 'विवरण')),
      for (final e in p.entries.where(
        (e) => !hiddenKeys.contains(e.key) && e.key != 'amountPaise',
      ))
        KeyValueRow(
          hrFieldLabel(e.key.toString()),
          e.value == null
              ? tr('Not set', 'सेट नहीं')
              : e.key == 'acknowledgment'
              ? (e.value == true
                    ? tr('Required', 'आवश्यक')
                    : tr('Not required', 'आवश्यक नहीं'))
              : (e.key.toString().toLowerCase().contains('date') ||
                    e.key.toString().endsWith('On'))
              ? formatDay(context, e.value)
              : '${e.value}',
        ),
      if (files.isNotEmpty) ...[
        SectionHeader(tr('Attachments', 'संलग्नक')),
        for (final (i, f) in files.indexed)
          ActionRow(
            icon: f['declared_type'] == 'application/pdf'
                ? AppIcons.fileDown
                : AppIcons.image,
            title: f['status'] == 'ready'
                ? tr(
                    'Protected attachment ${i + 1}',
                    'सुरक्षित संलग्नक ${i + 1}',
                  )
                : statusLabel('${f['status']}'),
            subtitle: f['status'] == 'ready'
                ? null
                : tr(
                    'Not available yet (scanning or rejected)',
                    'अभी उपलब्ध नहीं (स्कैन या अस्वीकृत)',
                  ),
            divider: i < files.length - 1,
            onTap: f['status'] == 'ready'
                ? () => context.go(
                    '$base/attachment/${f['id']}?type=${Uri.encodeComponent('${f['declared_type'] ?? ''}')}&title=${Uri.encodeComponent(recordTitle(widget.kind, r))}',
                  )
                : null,
          ),
      ],
    ];
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.show});
  final HrMap line;
  final bool show;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final proration =
        line['numerator'] != null &&
        line['denominator'] != null &&
        '${line['numerator']}' != '${line['denominator']}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${line['label']}', style: text.bodyLarge),
                if (proration)
                  Text(
                    tr(
                      'Prorated ${line['numerator']}/${line['denominator']}',
                      'आनुपातिक ${line['numerator']}/${line['denominator']}',
                    ),
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            show ? formatInr(line['calculatedPaise']) : '••••',
            style: text.titleMedium,
          ),
        ],
      ),
    );
  }
}

const recordFields = {
  'expense': ['amountPaise', 'date', 'category', 'description'],
  'asset': ['assetTag', 'name', 'serialNumber', 'condition'],
  'helpdesk': ['subject', 'category', 'description'],
  'grievance': ['subject', 'description'],
  'document': ['title', 'category', 'expiresOn', 'description'],
  'policy': ['title', 'effectiveOn', 'body'],
  'announcement': ['title', 'expiresOn', 'body'],
  'lifecycle': [
    'event',
    'effectiveOn',
    'employmentId',
    'destinationSiteId',
    'designation',
    'department',
    'salaryStructureId',
    'details',
  ],
};

class RecordEditorArgs {
  const RecordEditorArgs({required this.data, this.initial});
  final HrMap data;
  final HrMap? initial;
}

class RecordEditorPage extends ConsumerStatefulWidget {
  const RecordEditorPage({
    super.key,
    required this.scope,
    required this.kind,
    required this.args,
  });
  final SiteScope scope;
  final String kind;
  final RecordEditorArgs? args;
  @override
  ConsumerState<RecordEditorPage> createState() => _RecordEditorPageState();
}

class _RecordEditorPageState extends ConsumerState<RecordEditorPage> {
  late final UnsavedWork unsaved;
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final note = TextEditingController();
  late List<String> attachments, audience;
  String? employee;
  Object? error;
  bool busy = false, ack = false;
  String clientId = const Uuid().v4();
  HrMap get data => widget.args?.data ?? const {};
  HrMap? get initial => widget.args?.initial;
  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
    for (final k in recordFields[widget.kind] ?? const <String>[]) {
      var value = initial?['payload']?[k]?.toString() ?? '';
      if (k == 'amountPaise' && value.isNotEmpty) value = paiseText(value);
      if (widget.kind == 'document' && k == 'category' && value.isEmpty) {
        value = 'general';
      }
      controllers[k] = TextEditingController(text: value);
    }
    attachments = List<String>.from(initial?['attachments'] ?? const []);
    audience = List<String>.from(initial?['audience'] ?? const []);
    employee = initial?['employee_id'] ?? data['ownEmployeeId'];
    ack = initial?['payload']?['acknowledgment'] == true;
  }

  void dirty() => ref
      .read(unsavedWorkProvider)
      .mark(
        'record-editor',
        hrTitle(widget.kind),
        controllers.values.any((c) => c.text.isNotEmpty) ||
            note.text.isNotEmpty,
      );
  @override
  void dispose() {
    unsaved.mark('record-editor', '', false);
    for (final c in controllers.values) {
      c.dispose();
    }
    note.dispose();
    super.dispose();
  }

  List<(String, String)>? choices(String key) {
    if (key == 'category' && widget.kind == 'document') {
      return [
        ('general', tr('General', 'सामान्य')),
        ('identity', tr('Identity', 'पहचान')),
        ('bank', tr('Bank', 'बैंक')),
      ];
    }
    if (key == 'event') {
      return [
        for (final v in [
          'joining',
          'promotion',
          'transfer',
          'salary_revision',
          'probation',
          'confirmation',
          'exit',
        ])
          (v, v.replaceAll('_', ' ')),
      ];
    }
    if (key == 'destinationSiteId') {
      return [
        for (final s in (data['sites'] as List? ?? const []))
          (s['id'] as String, '${s['name']}'),
      ];
    }
    if (key == 'employmentId' || key == 'salaryStructureId') {
      return [
        for (final s
            in ((data[key == 'employmentId'
                            ? 'employments'
                            : 'salaryStructures']
                        as List? ??
                    const []))
                .where((s) => s['employee_id'] == employee))
          (
            s['id'] as String,
            key == 'employmentId'
                ? '${s['name']} · ${s['employer']}'
                : '${s['starts_on']} — ${s['ends_on']}',
          ),
      ];
    }
    return null;
  }

  Future<void> attach() async {
    final picture = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picture == null) return;
    setState(() => busy = true);
    try {
      final api = ref.read(apiProvider),
          bytes = await picture.readAsBytes(),
          epoch = api.scopeEpoch.capture();
      final response = await api.scopedWrite(
        widget.scope,
        documentNodeMutationHrCommand,
        {
          'operation': 'fileIntent',
          'input': {
            'clientId': const Uuid().v4(),
            'expectedVersion': initial!['version'],
            'id': initial!['id'],
            'type': picture.name.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg',
            'bytes': bytes.length,
          },
        },
      );
      final id = response['hrCommand']['id'];
      await api.uploadOperationPhoto(widget.scope, id, bytes);
      if (!api.scopeEpoch.isCurrent(epoch)) {
        throw StateError('Workspace changed');
      }
      if (mounted) {
        setState(() => attachments.add(id));
        showConfirmation(
          context,
          tr('Attachment uploaded', 'संलग्नक अपलोड हुआ'),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final payload = <String, dynamic>{
        for (final e in controllers.entries) e.key: e.value.text.trim(),
      };
      if (payload.containsKey('amountPaise')) {
        final rupees =
            double.tryParse(
              payload['amountPaise'].toString().replaceAll(',', ''),
            ) ??
            0;
        payload['amountPaise'] = (rupees * 100).round().toString();
      }
      for (final key in [
        'expiresOn',
        'destinationSiteId',
        'salaryStructureId',
      ]) {
        if (payload[key] == '') payload[key] = null;
      }
      if (['policy', 'announcement'].contains(widget.kind)) {
        payload['acknowledgment'] = ack;
      }
      await ref.read(apiProvider).scopedWrite(
        widget.scope,
        documentNodeMutationHrCommand,
        {
          'operation': 'save',
          'input': {
            'clientId': clientId,
            'expectedVersion': initial?['version'] ?? 0,
            if (initial != null) 'id': initial!['id'],
            'kind': widget.kind,
            'employeeId': employee,
            'payload': payload,
            'attachments': attachments,
            'audience': audience,
            'note': note.text,
          },
        },
      );
      ref.invalidate(hrRecordsProvider((widget.scope, widget.kind)));
      unsaved.mark('record-editor', '', false);
      if (mounted) {
        showConfirmation(context, tr('Draft saved', 'ड्राफ़्ट सहेजा'));
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null) {
      return PageScaffold(
        title: hrTitle(widget.kind),
        body: ListView(
          padding: Space.page,
          children: [
            EmptyState(
              title: tr('Start from the list', 'सूची से शुरू करें'),
              message: tr(
                'New drafts are created from the ${hrTitle(widget.kind)} page.',
                'नए ड्राफ़्ट ${hrTitle(widget.kind)} पृष्ठ से बनाए जाते हैं।',
              ),
              illustration: TinyKind.clipboard,
              action: ActionButton(
                tr(
                  'Open ${hrTitle(widget.kind)}',
                  '${hrTitle(widget.kind)} खोलें',
                ),
                expanded: false,
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    final employees = (data['employees'] as List? ?? const []);
    final needsEmployee =
        ['asset', 'document', 'lifecycle'].contains(widget.kind) &&
        initial == null;
    return PageScaffold(
      title: initial == null
          ? _createLabel(widget.kind)
          : tr('Edit draft', 'ड्राफ़्ट बदलें'),
      body: Form(
        key: form,
        onChanged: dirty,
        child: FormPageBody(
          fields: [
            if (error != null) InlineError(error!),
            if (needsEmployee)
              AppDropdown<String>(
                label: tr('For employee', 'कर्मचारी के लिए'),
                value: employee,
                items: [
                  for (final e in employees)
                    (e['id'] as String, '${e['name']}'),
                  if (!employees.any((e) => e['id'] == data['ownEmployeeId']) &&
                      data['ownEmployeeId'] != null)
                    (data['ownEmployeeId'] as String, tr('Me', 'मैं')),
                ],
                onChanged: (v) => setState(() => employee = v),
              ),
            for (final e in controllers.entries) _field(e.key, e.value, text),
            if (['policy', 'announcement'].contains(widget.kind)) ...[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('Require acknowledgment', 'पुष्टि आवश्यक')),
                subtitle: Text(
                  tr(
                    'Each reader confirms they have read it',
                    'हर पाठक पढ़ने की पुष्टि करता है',
                  ),
                ),
                value: ack,
                onChanged: (v) => setState(() => ack = v),
              ),
              SectionHeader(
                tr('Audience', 'दर्शक'),
                subtitle: tr(
                  'Leave empty to publish to the whole site',
                  'पूरी साइट के लिए खाली छोड़ें',
                ),
              ),
              for (final e in employees)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${e['name']}'),
                  value: audience.contains(e['userId']),
                  onChanged: (v) => setState(
                    () => v == true
                        ? audience.add(e['userId'])
                        : audience.remove(e['userId']),
                  ),
                ),
            ],
            SectionHeader(tr('Attachments', 'संलग्नक')),
            if (initial != null)
              ActionButton(
                '${tr('Attach receipt / image', 'रसीद / फोटो जोड़ें')} · ${attachments.length}',
                icon: AppIcons.paperclip,
                variant: ButtonVariant.secondary,
                busy: busy,
                onPressed: busy ? null : attach,
              )
            else
              Text(
                tr(
                  'Save the draft first, then reopen it to attach files.',
                  'पहले ड्राफ़्ट सहेजें, फिर संलग्नक जोड़ें।',
                ),
                style: text.bodySmall,
              ),
            const SizedBox(height: 18),
            AppTextField(
              label: tr('Change reason', 'बदलाव का कारण'),
              controller: note,
              minLines: 2,
              maxLines: 4,
              help: tr(
                'At least 8 characters. Kept in the record history.',
                'कम से कम 8 अक्षर। रिकॉर्ड इतिहास में रहता है।',
              ),
              validator: (v) => (v?.trim().length ?? 0) < 8
                  ? tr('At least 8 characters', 'कम से कम 8 अक्षर')
                  : null,
            ),
          ],
          actions: [
            ActionButton(
              tr('Save draft', 'ड्राफ़्ट सहेजें'),
              icon: AppIcons.save,
              busy: busy,
              onPressed: busy ? null : save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String key, TextEditingController c, TextTheme text) {
    final options = choices(key);
    final optional = [
      'expiresOn',
      'destinationSiteId',
      'salaryStructureId',
      'designation',
      'department',
      'serialNumber',
    ].contains(key);
    if (options != null) {
      if (options.length <= 4 && key == 'category') {
        return ChoiceChips<String>(
          label: hrFieldLabel(key),
          value: c.text,
          items: options,
          onChanged: (v) => setState(() => c.text = v),
        );
      }
      return AppDropdown<String>(
        key: ValueKey('$key:$employee'),
        label: hrFieldLabel(key),
        value: c.text.isEmpty ? null : c.text,
        items: options,
        optional: optional,
        validator: (v) =>
            ['event', 'employmentId', 'category'].contains(key) && v == null
            ? tr('Required', 'आवश्यक')
            : null,
        onChanged: (v) => setState(() {
          c.text = v ?? '';
          clientId = const Uuid().v4();
        }),
      );
    }
    if (key.toLowerCase().contains('date') || key.endsWith('On')) {
      return DateField(
        label: hrFieldLabel(key),
        value: c.text.isEmpty ? null : c.text,
        optional: optional,
        validator: (v) => !optional && (v == null || v.isEmpty)
            ? tr('Required', 'आवश्यक')
            : null,
        onChanged: (v) => setState(() {
          c.text = v ?? '';
          clientId = const Uuid().v4();
        }),
      );
    }
    if (key == 'amountPaise') {
      return AppTextField(
        label: tr('Amount (₹)', 'राशि (₹)'),
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 14, right: 4),
          child: Text('₹'),
        ),
        help: tr('Rupees, up to two decimals', 'रुपये, दो दशमलव तक'),
        onChanged: (_) => clientId = const Uuid().v4(),
        validator: (v) {
          final n = double.tryParse((v ?? '').replaceAll(',', ''));
          return n == null || n <= 0
              ? tr(
                  'Enter an amount greater than zero',
                  'शून्य से अधिक राशि दर्ज करें',
                )
              : null;
        },
      );
    }
    final multiline = [
      'description',
      'body',
      'details',
      'condition',
    ].contains(key);
    return AppTextField(
      label: hrFieldLabel(key),
      controller: c,
      optional: optional,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 6 : 1,
      keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
      onChanged: (_) => clientId = const Uuid().v4(),
      validator: (v) => optional
          ? null
          : (v == null || v.trim().isEmpty)
          ? tr('Required', 'आवश्यक')
          : null,
    );
  }
}

/// In-shell protected viewer for images and PDFs. Bytes are fetched with the
/// original scope and never cached on disk.
class AttachmentViewerPage extends ConsumerStatefulWidget {
  const AttachmentViewerPage({
    super.key,
    required this.scope,
    required this.id,
    this.declaredType,
    this.title,
    this.bytes,
  });
  final SiteScope scope;
  final String id;
  final String? declaredType, title;

  /// Locally generated content (a payslip PDF) passed as the route's extra.
  final Uint8List? bytes;
  @override
  ConsumerState<AttachmentViewerPage> createState() =>
      _AttachmentViewerPageState();
}

class _AttachmentViewerPageState extends ConsumerState<AttachmentViewerPage> {
  Uint8List? bytes;
  Object? error;
  @override
  void initState() {
    super.initState();
    bytes = widget.bytes;
    if (bytes == null) load();
  }

  Future<void> load() async {
    setState(() => error = null);
    try {
      final api = ref.read(apiProvider), epoch = api.scopeEpoch.capture();
      final data = await api.downloadOperationFile(widget.scope, widget.id);
      if (!mounted || !api.scopeEpoch.isCurrent(epoch)) return;
      setState(() => bytes = data);
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  bool get isPdf {
    final b = bytes;
    if (widget.declaredType == 'application/pdf') return true;
    return b != null &&
        b.length > 4 &&
        b[0] == 0x25 &&
        b[1] == 0x50 &&
        b[2] == 0x44 &&
        b[3] == 0x46;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: widget.title ?? tr('Attachment', 'संलग्नक'),
      body: PrivacyShield(
        child: error != null
            ? ListView(
                padding: Space.page,
                children: [InlineError(error!, retry: load)],
              )
            : bytes == null
            ? ListView(
                padding: Space.page,
                children: const [
                  LoadingState(rows: 1, rowHeight: 320, header: false),
                ],
              )
            : isPdf
            ? PdfPreview(
                build: (_) async => bytes!,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfPreviewPageDecoration: const BoxDecoration(),
                loadingWidget: const Center(child: CircularProgressIndicator()),
                onError: (context, e) =>
                    Padding(padding: Space.page, child: InlineError(e)),
              )
            : Column(
                children: [
                  Expanded(
                    child: InteractiveViewer(
                      maxScale: 5,
                      child: Center(
                        child: Image.memory(
                          bytes!,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => Padding(
                            padding: Space.page,
                            child: EmptyState(
                              title: tr(
                                'Cannot display this file',
                                'यह फ़ाइल नहीं दिखाई जा सकती',
                              ),
                              message: tr(
                                'It is not an image or PDF. Use the authorized HR download instead.',
                                'यह चित्र या PDF नहीं है। अधिकृत एचआर डाउनलोड का उपयोग करें।',
                              ),
                              illustration: TinyKind.lock,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      tr(
                        'Protected preview · pinch to zoom',
                        'सुरक्षित पूर्वावलोकन · ज़ूम के लिए पिंच करें',
                      ),
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

const _methods = {
  'bank_transfer': 'Bank transfer',
  'upi': 'UPI',
  'cheque': 'Cheque',
  'cash': 'Cash',
};

/// Payment state of an approved/published payroll result; null while it is not
/// payable yet or after a later revision replaced it.
StatusPill? paymentPill(HrMap r) {
  final due = BigInt.tryParse('${r['duePaise']}');
  if (due == null) return null;
  if (due <= BigInt.zero) {
    return StatusPill(tr('Paid', 'भुगतान हुआ'), tone: StatusTone.success);
  }
  final paid = BigInt.tryParse('${r['paidPaise']}') ?? BigInt.zero;
  return paid > BigInt.zero
      ? StatusPill(tr('Part paid', 'आंशिक भुगतान'), tone: StatusTone.warning)
      : StatusPill(
          tr('Payment pending', 'भुगतान लंबित'),
          tone: StatusTone.warning,
        );
}
