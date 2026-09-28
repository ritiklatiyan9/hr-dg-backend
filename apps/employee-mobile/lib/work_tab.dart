import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';
import 'approvals.dart';
import 'attendance.dart';
import 'dwr_screen.dart';
import 'hr_services.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';

class WorkTab extends ConsumerWidget {
  const WorkTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(currentScopeProvider);
    if (scope == null) {
      return TabRoot(child: ChooseSitePage(title: tr('Work', 'कार्य')));
    }
    return TabRoot(
      child: _WorkBody(key: ValueKey(scope), scope: scope),
    );
  }
}

class _WorkBody extends ConsumerWidget {
  const _WorkBody({super.key, required this.scope});
  final SiteScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(capabilityProvider(scope));
    return PageScaffold(
      title: tr('Work', 'कार्य'),
      body: access.when(
        loading: () => ListView(
          padding: Space.page,
          children: const [LoadingState(rows: 5)],
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
        data: (data) => _Sections(scope: scope, access: data),
      ),
    );
  }
}

class _Sections extends ConsumerWidget {
  const _Sections({required this.scope, required this.access});
  final SiteScope scope;
  final dynamic access;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = List<String>.from(access.scope.capabilities);
    bool can(String k) => caps.contains(k);
    final ops = ref.watch(operationsProvider(scope));
    final runtime = ref.watch(operationRuntimeProvider);
    final dwr = can('my_dwr.view')
        ? ref.watch(dwrHomeProvider(scope)).value
        : null;
    final queue = hasApprovalCapability(caps)
        ? ref.watch(hrQueueProvider(scope)).value
        : null;
    final text = Theme.of(context).textTheme;
    final daily = <Widget>[];
    if (can('my_attendance.view')) {
      final status = ops.loaded ? attendanceStatus(ops, runtime, scope) : null;
      daily.add(
        ActionRow(
          icon: AppIcons.clock3,
          title: tr('Attendance', 'उपस्थिति'),
          subtitle: status == null
              ? tr('Check-in, hours and history', 'चेक-इन, घंटे और इतिहास')
              : status.checkedIn
              ? tr(
                  'Checked in at ${formatTime(context, status.since?.toIso8601String())}',
                  '${formatTime(context, status.since?.toIso8601String())} बजे चेक-इन',
                )
              : ops.configured
              ? tr('Not checked in today', 'आज चेक-इन नहीं हुआ')
              : tr(
                  'Not configured at this site yet',
                  'इस साइट पर अभी सेट नहीं',
                ),
          trailing: status?.verification == 'pending_verification'
              ? StatusPill(tr('Pending', 'लंबित'), tone: StatusTone.warning)
              : null,
          onTap: () => context.go('/work/attendance'),
        ),
      );
    }
    if (can('my_dwr.view')) {
      final today = dwr == null ? null : todaysReport(dwr);
      daily.add(
        ActionRow(
          icon: AppIcons.messagesSquare,
          title: tr('Daily Report', 'दैनिक रिपोर्ट'),
          subtitle:
              'DWR ${tr('chat', 'चैट')} · ${today == null ? tr('Tell your agent about today', 'आज का काम बताएँ') : statusLabel(today['status'])}',
          accent: today?['status'] == 'returned',
          onTap: () => context.go('/work/daily-report'),
        ),
      );
    }
    if (can('my_attendance.view')) {
      final open = ops.ownTasks.where((t) => t['status'] != 'done').length;
      daily.add(
        ActionRow(
          icon: AppIcons.listTodo,
          title: tr('Tasks', 'कार्य'),
          subtitle: ops.loaded
              ? tr('$open open', '$open खुले')
              : tr('Assigned work and progress', 'सौंपा गया काम और प्रगति'),
          count: open,
          onTap: () => context.go('/work/tasks'),
        ),
      );
      daily.add(
        ListenableBuilder(
          listenable: runtime,
          builder: (context, _) => ActionRow(
            icon: AppIcons.compass,
            title: tr('Field Duty', 'फील्ड ड्यूटी'),
            subtitle: runtime.tracking
                ? tr(
                    'Tracking on · location is being recorded',
                    'ट्रैकिंग चालू · स्थान दर्ज हो रहा है',
                  )
                : tr(
                    'Visits, duty tracking and routes',
                    'दौरे, ड्यूटी ट्रैकिंग और मार्ग',
                  ),
            trailing: runtime.tracking
                ? StatusPill(
                    tr('Live', 'लाइव'),
                    tone: StatusTone.success,
                    icon: AppIcons.circleDot,
                  )
                : null,
            onTap: () => context.go('/work/field-duty'),
          ),
        ),
      );
    }
    final requests = <Widget>[];
    if (can('my_leave.view')) {
      final balances = ops.balances;
      final total = balances.fold<double>(
        0,
        (n, b) => n + (double.tryParse('${b['balance']}') ?? 0),
      );
      requests.add(
        ActionRow(
          icon: AppIcons.treePalm,
          title: tr('Leave', 'छुट्टी'),
          subtitle: ops.loaded && balances.isNotEmpty
              ? tr(
                  '${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 1)} days available',
                  '${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 1)} दिन उपलब्ध',
                )
              : tr(
                  'Balances, requests and approvals',
                  'शेष, अनुरोध और स्वीकृति',
                ),
          count: ops.leaveRequests
              .where((l) => l['status'] == 'pending')
              .length,
          onTap: () => context.go('/work/leave'),
        ),
      );
    }
    if (can('my_attendance.view')) {
      requests.add(
        ActionRow(
          icon: AppIcons.calendarCog,
          title: tr('Fix Attendance', 'उपस्थिति सुधारें'),
          subtitle: tr(
            'Correction or overtime request',
            'सुधार या ओवरटाइम अनुरोध',
          ),
          count: ops.adjustments.where((a) => a['status'] == 'pending').length,
          onTap: () => context.go('/work/attendance/fix'),
        ),
      );
    }
    if (can('expenses.view')) {
      requests.add(
        ActionRow(
          icon: AppIcons.walletCards,
          title: tr('Expenses', 'व्यय'),
          subtitle: tr(
            'Claims, receipts and settlement',
            'दावे, रसीदें और निपटान',
          ),
          onTap: () => context.go(recordRoute('expense')),
        ),
      );
    }
    if (can('helpdesk.view')) {
      requests.add(
        ActionRow(
          icon: AppIcons.headset,
          title: tr('Helpdesk', 'सहायता'),
          subtitle: tr(
            'Ask HR a question or raise a request',
            'एचआर से प्रश्न या अनुरोध',
          ),
          onTap: () => context.go(recordRoute('helpdesk')),
        ),
      );
    }
    if (can('grievances.view')) {
      requests.add(
        ActionRow(
          icon: AppIcons.lockKeyhole,
          title: tr('Confidential grievance', 'गोपनीय शिकायत'),
          subtitle: tr(
            'Only you and assigned handlers can see it',
            'केवल आप और नियुक्त अधिकारी देख सकते हैं',
          ),
          onTap: () => context.go(recordRoute('grievance')),
        ),
      );
    }
    final team = <Widget>[];
    if (can('employees.view')) {
      team.add(
        ActionRow(
          icon: AppIcons.usersRound,
          title: tr('Team attendance', 'टीम उपस्थिति'),
          subtitle: tr(
            "Today's sessions for your assigned people",
            'नियुक्त लोगों के आज के सत्र',
          ),
          onTap: () => context.go('/work/team/attendance'),
        ),
      );
    }
    if (can('dwr_review.view')) {
      final toReview = dwr == null
          ? 0
          : (dwr['reports'] as List)
                .where((r) => r['isSelf'] != true && r['status'] == 'submitted')
                .length;
      team.add(
        ActionRow(
          icon: AppIcons.clipboardCheck,
          title: tr('Team reports', 'टीम रिपोर्ट'),
          subtitle: tr(
            'Daily reports sent to you for review',
            'समीक्षा के लिए भेजी गई दैनिक रिपोर्ट',
          ),
          count: toReview,
          onTap: () => context.go('/work/daily-report?queue=team'),
        ),
      );
    }
    if (hasApprovalCapability(caps)) {
      final counts = approvalCounts(queue, ops, scope, dwr);
      team.add(
        ActionRow(
          icon: AppIcons.stamp,
          title: tr('Approvals', 'स्वीकृतियाँ'),
          subtitle: tr(
            'Leave, attendance, expenses and more',
            'छुट्टी, उपस्थिति, व्यय और अन्य',
          ),
          count: counts.total,
          onTap: () => context.go('/work/approvals'),
        ),
      );
    }
    if (can('employees.view')) {
      team.add(
        ActionRow(
          icon: AppIcons.usersRound,
          title: tr('People', 'लोग'),
          subtitle: tr('Your authorized team members', 'आपके अधिकृत टीम सदस्य'),
          onTap: () => context.go('/work/team'),
        ),
      );
    }
    if (can('access.view')) {
      team.add(
        ActionRow(
          icon: AppIcons.shieldUser,
          title: tr('Users & module access', 'उपयोगकर्ता और अनुमति'),
          subtitle: tr(
            'Review permissions at this site',
            'इस साइट पर अनुमति समीक्षा',
          ),
          onTap: () => context.go('/work/access'),
        ),
      );
    }
    if (can('analytics.view')) {
      team.add(
        ActionRow(
          icon: AppIcons.chartNoAxesCombined,
          title: tr('Management insights', 'प्रबंधन विश्लेषण'),
          subtitle: tr('Authorized site facts', 'अनुमत साइट तथ्य'),
          onTap: () => context.go('/work/insights'),
        ),
      );
    }
    final unreleased = (access.scope.modules as List)
        .where((m) => m.available == false && can('${m.id}.view'))
        .length;
    if (daily.isEmpty && requests.isEmpty && team.isEmpty) {
      return ListView(
        padding: Space.page,
        children: [
          EmptyState(
            title: tr(
              'No work modules at this site',
              'इस साइट पर कोई कार्य मॉड्यूल नहीं',
            ),
            message: tr(
              'Your HR team assigns module access per site. Try another site or contact HR.',
              'एचआर टीम साइट के अनुसार अनुमति देती है। दूसरी साइट चुनें या एचआर से संपर्क करें।',
            ),
            illustration: TinyKind.lock,
          ),
        ],
      );
    }
    return ListView(
      padding: Space.page,
      children: [
        if (daily.isNotEmpty) ...[
          SectionHeader(tr('Daily work', 'दैनिक कार्य'), top: 4),
          ...daily,
        ],
        if (requests.isNotEmpty) ...[
          SectionHeader(tr('Requests', 'अनुरोध')),
          ...requests,
        ],
        if (team.isNotEmpty) ...[
          SectionHeader(
            tr('Team', 'टीम'),
            subtitle: tr(
              'Only shown because your access allows it',
              'केवल आपकी अनुमति के कारण दिख रहा है',
            ),
          ),
          ...team,
        ],
        if (unreleased > 0)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              tr(
                '$unreleased permitted module(s) are not released yet at this site.',
                '$unreleased अनुमत मॉड्यूल इस साइट पर अभी जारी नहीं हैं।',
              ),
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}
