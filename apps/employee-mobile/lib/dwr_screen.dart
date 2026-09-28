import 'ui/icons.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'api.dart';
import 'dwr_chat.dart';
import 'providers.dart';
import 'scope.dart';
import 'mobile_ui.dart';
import 'operation_vault.dart';
import 'ui/components.dart';
import 'workspace.dart';
import 'graphql/operations.graphql.dart';

typedef DwrJson = Map<String, dynamic>;
String dwrStateLabel(String value) => tr(
  value,
  const {
        'Idle': 'तैयार',
        'Preview': 'जाँचें',
        'Submitting': 'भेजा जा रहा है',
        'Submitted': 'भेज दिया गया',
        'Recoverable error': 'फिर कोशिश करें',
        'Saved locally': 'स्थानीय रूप से सहेजा',
        'Saved draft': 'ड्राफ़्ट सहेजा',
        'draft': 'ड्राफ़्ट',
        'submitted': 'समीक्षा लंबित',
        'approved': 'स्वीकृत',
        'returned': 'वापस भेजी गई',
      }[value] ??
      value,
);
const dwrFields = {
  'completed': ['Completed work', 'पूरा किया काम'],
  'pending': ['Pending work / reasons', 'बाकी काम / कारण'],
  'blockers': ['Issues / blockers', 'समस्याएँ / बाधाएँ'],
  'nextDayPlan': ['Next-day plan', 'अगले दिन की योजना'],
  'uncertainties': ['Clarification needed', 'स्पष्टीकरण'],
};
const _fieldHints = {
  'completed': ['What you finished today', 'आज जो पूरा किया'],
  'pending': ['What is still open, and why', 'क्या बाकी है और क्यों'],
  'blockers': ['Anything that stopped you', 'जो आपको रोक रहा था'],
  'nextDayPlan': ['What you will do tomorrow', 'कल क्या करेंगे'],
  'uncertainties': ['Questions for your reviewer', 'समीक्षक के लिए प्रश्न'],
};
DwrJson blankDwr() => {
  'completed': <String>[],
  'pending': <String>[],
  'blockers': <String>[],
  'nextDayPlan': <String>[],
  'uncertainties': <String>[],
  'sourceTranscript': '',
  'status': 'draft',
  'stated': {
    'pending': 'not_stated',
    'blockers': 'not_stated',
    'nextDayPlan': 'not_stated',
  },
};

final dwrHomeProvider = FutureProvider.autoDispose.family<DwrJson, SiteScope>(
  (ref, s) async => Map<String, dynamic>.from(
    (await ref.watch(apiProvider).scopedRead(s, documentNodeQueryDwr))['dwr']
        as Map,
  ),
);

/// Encrypted drafts saved on this device for the scope's site and actor.
final localDwrDraftsProvider = FutureProvider.autoDispose
    .family<List<DwrJson>, SiteScope>((ref, s) async {
      final vault = await OperationVault.open(s.organizationId, s.actorId);
      return (await vault.entries(includeDwr: true))
          .where(
            (r) =>
                r['operation'] == 'dwr_draft' &&
                r['siteId'] == s.siteId &&
                r['actorId'] == s.actorId,
          )
          .toList();
    });

DwrJson? todaysReport(DwrJson data) {
  final rows = (data['reports'] as List? ?? const []);
  final row = rows
      .where((r) => r['isSelf'] == true && r['work_date'] == data['workDate'])
      .firstOrNull;
  return row == null ? null : Map<String, dynamic>.from(row as Map);
}

class DwrEditorArgs {
  const DwrEditorArgs({
    required this.report,
    required this.data,
    required this.caps,
    required this.vault,
    required this.offline,
  });
  final DwrJson report, data;
  final List<String> caps;
  final OperationVault vault;
  final bool offline;
}

DwrJson reportFromLocal(DwrJson d) => {
  ...Map<String, dynamic>.from(d['report'] as Map),
  'content': d['content'],
  'pendingRequest': d['pendingRequest'],
};

/// Opens the editor for an existing report or a local draft.
Future<void> openReportEditor(
  BuildContext context,
  WidgetRef ref, {
  required SiteScope scope,
  required DwrJson data,
  required List<String> caps,
  DwrJson? report,
  DwrJson? local,
}) async {
  final vault = await OperationVault.open(scope.organizationId, scope.actorId);
  final target = local != null
      ? reportFromLocal(local)
      : report ??
            {
              'version': 0,
              'status': 'draft',
              'isSelf': true,
              'work_date': data['workDate'],
              'content': blankDwr(),
              'attachments': [],
            };
  if (!context.mounted) return;
  await context.push(
    '/work/daily-report/edit',
    extra: DwrEditorArgs(
      report: target,
      data: data,
      caps: caps,
      vault: vault,
      offline: false,
    ),
  );
}

/// Report history: own DWRs by day, the team review queue and encrypted drafts.
class DailyReportPage extends ConsumerStatefulWidget {
  const DailyReportPage({super.key, required this.scope, this.queue = false});
  final SiteScope? scope;
  final bool queue;
  @override
  ConsumerState<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends ConsumerState<DailyReportPage> {
  SiteScope? scope;
  DwrJson? data;
  List<String> caps = [];
  OperationVault? vault;
  List<DwrJson> local = [];
  Object? error;
  bool offline = false, team = false, loading = true;
  @override
  void initState() {
    super.initState();
    scope = widget.scope;
    team = widget.queue;
    load();
  }

  Future<void> load() async {
    final api = ref.read(apiProvider);
    setState(() => loading = true);
    try {
      if (scope == null) {
        final identity = await api.storage.read(key: 'offline_identity');
        if (identity == null) {
          throw StateError(
            tr(
              'No saved account on this device.',
              'इस डिवाइस पर कोई सहेजा खाता नहीं।',
            ),
          );
        }
        final i = jsonDecode(identity) as Map;
        vault = await OperationVault.open(i['organizationId'], i['actorId']);
        final cached = await vault!.read('dwr_context');
        if (cached == null) {
          throw StateError(
            tr(
              'No local report drafts for this account.',
              'इस खाते के लिए कोई स्थानीय ड्राफ़्ट नहीं।',
            ),
          );
        }
        scope = SiteScope(
          cached['organizationId'],
          cached['actorId'],
          cached['permissionVersion'],
          cached['siteId'],
        );
      }
      vault ??= await OperationVault.open(
        scope!.organizationId,
        scope!.actorId,
      );
      try {
        final access = (await api.capabilities(scope!)).scope;
        caps = access.capabilities;
        if (!caps.any((c) => ['my_dwr.view', 'dwr_review.view'].contains(c))) {
          throw const ApiFailure(
            'FORBIDDEN',
            'Daily report access is restricted',
          );
        }
        data = Map<String, dynamic>.from(
          (await api.scopedRead(scope!, documentNodeQueryDwr))['dwr'],
        );
        offline = false;
        if (data!['settings']?['offline_drafts'] == true &&
            caps.contains('my_dwr.edit')) {
          await vault!.write('dwr_context', {
            'organizationId': scope!.organizationId,
            'actorId': scope!.actorId,
            'permissionVersion': scope!.permissionVersion,
            'siteId': scope!.siteId,
            'settings': data!['settings'],
            'workDate': data!['workDate'],
            'site': data!['site'],
            'caps': caps,
          });
          await api.storage.write(
            key: 'offline_identity',
            value: jsonEncode({
              'organizationId': scope!.organizationId,
              'actorId': scope!.actorId,
            }),
          );
        }
      } catch (e) {
        if (e is ApiFailure &&
            e.code != 'OFFLINE' &&
            e.code != 'NETWORK_ERROR') {
          rethrow;
        }
        final cached = await vault!.read('dwr_context');
        if (cached == null ||
            cached['siteId'] != scope!.siteId ||
            cached['settings']?['offline_drafts'] != true) {
          rethrow;
        }
        offline = true;
        caps = List<String>.from(cached['caps']);
        data = {...cached, 'reports': []};
      }
      local = (await vault!.entries(includeDwr: true))
          .where(
            (r) =>
                r['operation'] == 'dwr_draft' &&
                r['siteId'] == scope!.siteId &&
                r['actorId'] == scope!.actorId,
          )
          .toList();
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> open(DwrJson report) async {
    await context.push(
      '/work/daily-report/edit',
      extra: DwrEditorArgs(
        report: report,
        data: data!,
        caps: caps,
        vault: vault!,
        offline: offline,
      ),
    );
    await load();
    if (scope != null) {
      ref.invalidate(dwrHomeProvider(scope!));
      ref.invalidate(localDwrDraftsProvider(scope!));
      ref.invalidate(dwrChatHomeProvider(scope!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final d = data;
    final today = d == null ? null : todaysReport(d);
    final localToday = d == null
        ? null
        : local.where((x) => x['workDate'] == d['workDate']).firstOrNull;
    final reports = ((d?['reports'] ?? const []) as List)
        .where((r) => team ? r['isSelf'] != true : r['isSelf'] == true)
        .toList();
    return PageScaffold(
      title: team
          ? tr('Team reports', 'टीम रिपोर्ट')
          : tr('My reports', 'मेरी रिपोर्ट'),
      showSite: widget.scope != null,
      actions: [
        IconButton(
          tooltip: tr('Reload', 'पुनः लोड'),
          onPressed: loading ? null : load,
          icon: const AppIcon(AppIcons.rotateCw),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: load,
        child: error != null && d == null
            ? ListView(
                padding: Space.page,
                children: [InlineError(error!, retry: load)],
              )
            : d == null
            ? ListView(
                padding: Space.page,
                children: const [LoadingState(rows: 3, rowHeight: 90)],
              )
            : ListView(
                padding: Space.page,
                children: [
                  if (offline)
                    NoticeBanner(
                      tr(
                        'Offline · drafts stay at their original site. Send after reconnecting.',
                        'ऑफ़लाइन · ड्राफ़्ट मूल साइट पर रहेंगे। कनेक्ट होने पर भेजें।',
                      ),
                      tone: StatusTone.warning,
                      icon: AppIcons.cloudOff,
                    ),
                  if (error != null)
                    InlineError(error!, retry: load, compact: true),
                  if (!team)
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDay(context, d['workDate']),
                                  style: text.titleLarge,
                                ),
                              ),
                              if (today != null)
                                StatusPill.status('${today['status']}')
                              else if (localToday != null)
                                StatusPill(
                                  tr(
                                    'Draft on this device',
                                    'इस डिवाइस पर ड्राफ़्ट',
                                  ),
                                  tone: StatusTone.accent,
                                  icon: AppIcons.smartphone,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            today == null
                                ? tr(
                                    'Tell your DWR agent what you worked on. Your report is prepared from your chat.',
                                    'अपने DWR एजेंट को आज का काम बताएँ। आपकी रिपोर्ट चैट से तैयार होगी।',
                                  )
                                : today['status'] == 'returned'
                                ? tr(
                                    'Your reviewer sent it back with notes. Open it to make changes.',
                                    'समीक्षक ने टिप्पणी के साथ वापस भेजा। बदलाव के लिए खोलें।',
                                  )
                                : tr(
                                    "Today's report is ready to open.",
                                    'आज की रिपोर्ट खोलने के लिए तैयार है।',
                                  ),
                            style: text.bodyMedium?.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (today != null)
                            ActionButton(
                              today['status'] == 'draft' ||
                                      today['status'] == 'returned'
                                  ? tr('Review & submit', 'जाँचें और भेजें')
                                  : tr('View report', 'रिपोर्ट देखें'),
                              icon: AppIcons.fileText,
                              variant: today['status'] == 'returned'
                                  ? ButtonVariant.primary
                                  : ButtonVariant.secondary,
                              onPressed: () =>
                                  open(Map<String, dynamic>.from(today)),
                            )
                          else if (localToday != null)
                            ActionButton(
                              tr('Continue draft', 'ड्राफ़्ट जारी रखें'),
                              icon: AppIcons.pencil,
                              onPressed: () =>
                                  open(reportFromLocal(localToday)),
                            )
                          else
                            ActionButton(
                              tr('Open DWR chat', 'DWR चैट खोलें'),
                              icon: AppIcons.messagesSquare,
                              onPressed: () => context.go('/work/daily-report'),
                            ),
                        ],
                      ),
                    ),
                  if (local.isNotEmpty) ...[
                    SectionHeader(
                      tr('Saved on this device', 'इस डिवाइस पर सहेजे'),
                      subtitle: tr(
                        'Encrypted drafts that are not on the server yet',
                        'एन्क्रिप्टेड ड्राफ़्ट जो अभी सर्वर पर नहीं हैं',
                      ),
                    ),
                    for (final (i, l) in local.indexed)
                      ActionRow(
                        icon: AppIcons.smartphone,
                        title: formatDay(context, l['workDate']),
                        subtitle: tr(
                          'Resume encrypted draft',
                          'एन्क्रिप्टेड ड्राफ़्ट जारी रखें',
                        ),
                        trailing: StatusPill(
                          tr('Local', 'स्थानीय'),
                          tone: StatusTone.accent,
                        ),
                        divider: i < local.length - 1,
                        onTap: () => open(reportFromLocal(l)),
                      ),
                  ],
                  SectionHeader(
                    team
                        ? tr('Team reports', 'टीम रिपोर्ट')
                        : tr('My reports', 'मेरी रिपोर्ट'),
                    trailing: caps.contains('dwr_review.view')
                        ? SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(tr('Mine', 'मेरी')),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(tr('Team', 'टीम')),
                              ),
                            ],
                            selected: {team},
                            onSelectionChanged: (v) =>
                                setState(() => team = v.first),
                          )
                        : null,
                  ),
                  if (reports.isEmpty)
                    EmptyState(
                      title: team
                          ? tr(
                              'No reports to review',
                              'समीक्षा के लिए कोई रिपोर्ट नहीं',
                            )
                          : tr('No reports yet', 'अभी कोई रिपोर्ट नहीं'),
                      message: team
                          ? tr(
                              'Reports sent to you, and drafts prepared from your team\'s chats, appear here.',
                              'आपको भेजी गई रिपोर्ट और टीम की चैट से बने ड्राफ़्ट यहाँ दिखेंगे।',
                            )
                          : tr(
                              'Your daily reports and their outcomes will be listed here.',
                              'आपकी दैनिक रिपोर्ट और उनके परिणाम यहाँ दिखेंगे।',
                            ),
                      illustration: TinyKind.clipboard,
                    ),
                  for (final (i, r) in reports.indexed)
                    ActionRow(
                      icon: r['status'] == 'approved'
                          ? AppIcons.circleCheck
                          : r['status'] == 'submitted'
                          ? AppIcons.sendHorizontal
                          : r['origin'] == 'chat'
                          ? AppIcons.messagesSquare
                          : AppIcons.fileText,
                      title: team
                          ? '${r['employeeName']}'
                          : formatDay(context, r['work_date']),
                      subtitle: team
                          ? formatDay(context, r['work_date'])
                          : '${tr('Revision', 'संशोधन')} ${r['revision']}',
                      trailing: StatusPill.status('${r['status']}'),
                      divider: i < reports.length - 1,
                      onTap: () => open(Map<String, dynamic>.from(r)),
                    ),
                ],
              ),
      ),
    );
  }
}

class DwrEditorPage extends StatelessWidget {
  const DwrEditorPage({super.key, required this.scope, required this.args});
  final SiteScope scope;
  final DwrEditorArgs? args;
  @override
  Widget build(BuildContext context) {
    final a = args;
    if (a == null) {
      return PageScaffold(
        title: tr('Daily Report', 'दैनिक रिपोर्ट'),
        body: ListView(
          padding: Space.page,
          children: [
            EmptyState(
              title: tr('Open a report first', 'पहले रिपोर्ट खोलें'),
              message: tr(
                'Reports are opened from your DWR chat or report list so the right site and draft are loaded.',
                'रिपोर्ट DWR चैट या सूची से खोली जाती हैं ताकि सही साइट और ड्राफ़्ट लोड हो।',
              ),
              illustration: TinyKind.clipboard,
              action: ActionButton(
                tr('Go to DWR chat', 'DWR चैट पर जाएँ'),
                expanded: false,
                onPressed: () => context.go('/work/daily-report'),
              ),
            ),
          ],
        ),
      );
    }
    return DwrEditor(
      scope: scope,
      report: a.report,
      data: a.data,
      caps: a.caps,
      vault: a.vault,
      offline: a.offline,
    );
  }
}

class DwrEditor extends ConsumerStatefulWidget {
  const DwrEditor({
    super.key,
    required this.scope,
    required this.report,
    required this.data,
    required this.caps,
    required this.vault,
    required this.offline,
  });
  final SiteScope scope;
  final DwrJson report, data;
  final List<String> caps;
  final OperationVault vault;
  final bool offline;
  @override
  ConsumerState<DwrEditor> createState() => _DwrEditorState();
}

class _DwrEditorState extends ConsumerState<DwrEditor> {
  late final UnsavedWork unsaved;
  late DwrJson report, stated;
  final controls = <String, TextEditingController>{};
  final transcript = TextEditingController(), reason = TextEditingController();
  late String date;
  Object? error;
  String stage = 'Idle';
  bool busy = false, dirty = false;
  List<String> attachments = [];
  DwrJson? pendingRequest, submitInput;
  final firstField = FocusNode();

  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
    report = {...widget.report};
    if (report['status'] != 'draft') stage = report['status'];
    date = report['work_date'];
    attachments = List<String>.from(report['attachments'] ?? []);
    pendingRequest = report['pendingRequest'];
    if (pendingRequest != null) {
      final pending = jsonDecode(pendingRequest!['signature']) as Map;
      if (pending['operation'] == 'submit') {
        submitInput = Map<String, dynamic>.from(pending['input']);
      }
    }
    for (final key in dwrFields.keys) {
      controls[key] = TextEditingController()..addListener(markDirty);
    }
    fill(Map<String, dynamic>.from(report['content']));
    dirty = false;
  }

  void markDirty() {
    if (!editable || dirty) return;
    dirty = true;
    ref
        .read(unsavedWorkProvider)
        .mark('dwr', tr('Daily report', 'दैनिक रिपोर्ट'), true);
  }

  void clearDirty() {
    dirty = false;
    unsaved.mark('dwr', '', false);
  }

  void fill(DwrJson c) {
    for (final key in dwrFields.keys) {
      controls[key]!.text = (c[key] as List).join('\n');
    }
    transcript.text = c['sourceTranscript'] ?? '';
    stated = Map<String, dynamic>.from(c['stated']);
  }

  DwrJson content() {
    final result = blankDwr();
    for (final key in dwrFields.keys) {
      result[key] = controls[key]!.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    result['sourceTranscript'] = transcript.text;
    result['stated'] = {
      for (final key in stated.keys)
        key: (result[key] as List).isNotEmpty
            ? 'reported'
            : stated[key] == 'none'
            ? 'none'
            : 'not_stated',
    };
    return result;
  }

  bool get editable =>
      report['isSelf'] == true &&
      ['draft', 'returned'].contains(report['status']) &&
      widget.caps.contains(
        report['id'] == null ? 'my_dwr.create' : 'my_dwr.edit',
      );
  bool get offlineDrafts => widget.data['settings']?['offline_drafts'] == true;
  String get localId => 'dwr_${widget.scope.siteId}_$date';

  Future<void> localSave() async {
    if (!offlineDrafts) {
      throw StateError(
        tr(
          'Offline drafts are not enabled at this site. Save online.',
          'ऑफ़लाइन ड्राफ़्ट अनुमति नहीं। ऑनलाइन सहेजें।',
        ),
      );
    }
    await widget.vault.write(localId, {
      'id': localId,
      'operation': 'dwr_draft',
      'organizationId': widget.scope.organizationId,
      'actorId': widget.scope.actorId,
      'siteId': widget.scope.siteId,
      'workDate': date,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'payloadVersion': 1,
      'state': 'saved_locally',
      'report': {...report, 'work_date': date, 'attachments': attachments},
      'content': content(),
      'pendingRequest': pendingRequest,
    });
  }

  Future<DwrJson> command(String op, DwrJson input) async {
    final signature = jsonEncode({'operation': op, 'input': input});
    if (pendingRequest?['signature'] != signature) {
      pendingRequest = {'signature': signature, 'clientId': const Uuid().v4()};
    }
    // Review/approval requests stay online and must never enter local draft storage.
    if (editable && offlineDrafts) await localSave();
    final result = await ref.read(apiProvider).scopedWrite(
      widget.scope,
      documentNodeMutationDwrCommand,
      {
        'operation': op,
        'input': {...input, 'clientId': pendingRequest!['clientId']},
      },
    );
    pendingRequest = null;
    return Map<String, dynamic>.from(result['dwrCommand']);
  }

  Future<DwrJson> save() async {
    final receipt = await command('save', {
      'expectedVersion': report['version'],
      'workDate': date,
      'content': content(),
      'attachments': attachments,
    });
    report = {
      ...report,
      ...receipt,
      'work_date': date,
      'attachments': attachments,
    };
    if (offlineDrafts) await localSave();
    clearDirty();
    return report;
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (editable && offlineDrafts) {
        try {
          await localSave();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          error = e;
          stage = 'Recoverable error';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> attach() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
    );
    if (photo == null) return;
    await run(() async {
      final saved = await save();
      final bytes = await photo.readAsBytes();
      final intent = await command('fileIntent', {
        'id': saved['id'],
        'type': photo.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg',
        'bytes': bytes.length,
      });
      await ref
          .read(apiProvider)
          .uploadOperationPhoto(widget.scope, intent['id'], bytes);
      setState(() => attachments.add(intent['id']));
    });
  }

  Future<void> submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        title: Text(tr('Confirm submission', 'भेजने की पुष्टि')),
        content: Text(
          tr(
            'I reviewed these employee-reported details and want to send them for review. That day\'s chat messages are then locked unless the report is sent back.',
            'मैंने इन विवरणों को जाँचा है और समीक्षा के लिए भेजना चाहता हूँ। इसके बाद उस दिन के चैट संदेश लॉक हो जाएँगे, जब तक रिपोर्ट वापस न भेजी जाए।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(tr('Keep editing', 'संपादन जारी रखें')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('Confirm', 'पुष्टि करें')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await run(() async {
      setState(() => stage = 'Submitting');
      if (submitInput == null) {
        // An unchanged prepared draft is submitted as-is; edits are saved first.
        final saved = dirty || report['id'] == null ? await save() : report;
        submitInput = {
          'id': saved['id'],
          'expectedVersion': saved['version'],
          'confirmed': true,
        };
      }
      final receipt = await command('submit', submitInput!);
      report = {...report, ...receipt};
      submitInput = null;
      await widget.vault.remove(localId);
      clearDirty();
      setState(() => stage = 'Submitted');
      HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    unsaved.mark('dwr', '', false);
    for (final c in controls.values) {
      c.dispose();
    }
    transcript.dispose();
    reason.dispose();
    firstField.dispose();
    super.dispose();
  }

  String? get returnNote {
    final history = (report['history'] as List? ?? const []);
    final last = history.where((h) => h['event'] == 'return').firstOrNull;
    return last?['reason']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final chat = report['origin'] == 'chat';
    final canSubmit =
        editable &&
        !busy &&
        !widget.offline &&
        widget.caps.contains('my_dwr.submit');
    return PageScaffold(
      title: tr('Daily Report', 'दैनिक रिपोर्ट'),
      showSite: false,
      body: ListView(
        padding: Space.page,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDay(context, date), style: text.titleLarge),
                    Text(
                      '${widget.data['site']?['name'] ?? ''}${report['isSelf'] == true ? '' : ' · ${report['employeeName'] ?? ''}'}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (stage == 'Submitted')
                StatusPill(
                  dwrStateLabel('Submitted'),
                  tone: StatusTone.success,
                  icon: AppIcons.check,
                )
              else
                StatusPill.status('${report['status']}'),
            ],
          ),
          if (chat) ...[
            const SizedBox(height: 8),
            StatusPill(
              tr('Prepared from chat', 'चैट से तैयार'),
              tone: StatusTone.accent,
              icon: AppIcons.ai,
            ),
          ],
          if (stage == 'Submitted') ...[
            const SizedBox(height: 14),
            ConfirmedCheck(
              label: tr('Sent for review', 'समीक्षा के लिए भेजा गया'),
              detail: tr(
                'Your reviewer will see it now. Nothing else is required from you.',
                'आपका समीक्षक इसे अब देखेगा। आपसे और कुछ आवश्यक नहीं।',
              ),
            ),
          ],
          if (report['isSelf'] != true && report['status'] == 'draft') ...[
            const SizedBox(height: 10),
            NoticeBanner(
              tr(
                'Prepared from the employee\'s chat and not yet submitted by them. Review opens after submission.',
                'कर्मचारी की चैट से तैयार, अभी उन्होंने भेजी नहीं। भेजने के बाद समीक्षा होगी।',
              ),
              icon: AppIcons.info,
            ),
          ],
          if (editable &&
              report['status'] == 'returned' &&
              returnNote != null) ...[
            const SizedBox(height: 10),
            NoticeBanner(
              '${tr('Sent back', 'वापस भेजा')}: $returnNote',
              tone: StatusTone.warning,
              icon: AppIcons.messageSquareText,
            ),
          ],
          if (editable) ...[
            const SizedBox(height: 12),
            Text(
              chat
                  ? tr(
                      'Your DWR agent prepared this from your chat. Check each line, correct anything, then submit.',
                      'आपके DWR एजेंट ने इसे आपकी चैट से तैयार किया है। हर पंक्ति जाँचें, सुधारें, फिर भेजें।',
                    )
                  : tr(
                      'Check each line, correct anything, then submit.',
                      'हर पंक्ति जाँचें, सुधारें, फिर भेजें।',
                    ),
              style: text.bodyMedium?.copyWith(color: t.textSecondary),
            ),
          ],
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                busy
                    ? '${dwrStateLabel(stage)}…'
                    : (stage == 'Idle' || stage == 'Submitted')
                    ? ''
                    : dwrStateLabel(stage),
                style: text.labelMedium,
              ),
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(),
            ),
          if (error != null) InlineError(error!),
          SectionHeader(
            editable
                ? tr('Your report', 'आपकी रिपोर्ट')
                : tr('Report', 'रिपोर्ट'),
            subtitle: tr(
              'Employee-reported claims. No payroll approval or payment is implied.',
              'कर्मचारी द्वारा दिए विवरण। वेतन स्वीकृति या भुगतान का प्रमाण नहीं।',
            ),
          ),
          for (final (i, field) in dwrFields.entries.indexed) ...[
            if (editable)
              LabeledField(
                label: tr(field.value[0], field.value[1]),
                optional:
                    stated.containsKey(field.key) ||
                    field.key == 'uncertainties',
                child: TextField(
                  key: ValueKey('dwr-field-${field.key}'),
                  focusNode: i == 0 ? firstField : null,
                  controller: controls[field.key],
                  readOnly: busy,
                  minLines: 2,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        '${tr(_fieldHints[field.key]![0], _fieldHints[field.key]![1])} · ${tr('one item per line', 'हर पंक्ति में एक बात')}',
                  ),
                ),
              )
            else
              _ReadOnlyGroup(
                label: tr(field.value[0], field.value[1]),
                lines: controls[field.key]!.text,
                statedValue: stated[field.key],
              ),
            if (editable && stated.containsKey(field.key))
              ListenableBuilder(
                listenable: controls[field.key]!,
                builder: (context, _) =>
                    controls[field.key]!.text.trim().isNotEmpty
                    ? const SizedBox.shrink()
                    : Transform.translate(
                        offset: const Offset(0, -10),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            tr('Nothing to report here', 'यहाँ कुछ नहीं बताना'),
                            style: text.bodyMedium,
                          ),
                          value: stated[field.key] == 'none',
                          onChanged: busy
                              ? null
                              : (v) => setState(
                                  () => stated[field.key] = v == true
                                      ? 'none'
                                      : 'not_stated',
                                ),
                        ),
                      ),
              ),
          ],
          if (report['id'] != null && !widget.offline)
            DwrDaySources(
              scope: widget.scope,
              employeeId: report['employee_id']?.toString(),
              workDate: date,
            ),
          if (!chat &&
              transcript.text.trim().isNotEmpty &&
              report['provenanceVisible'] != false)
            ExpansionTile(
              title: Text(
                tr('Transcript', 'ट्रांसक्रिप्ट'),
                style: text.titleSmall,
              ),
              children: [
                SelectableText(transcript.text, style: text.bodyMedium),
                const SizedBox(height: 8),
              ],
            ),
          SectionHeader(tr('Attachments', 'संलग्नक')),
          if (attachments.isEmpty)
            Text(
              tr('No attachments.', 'कोई संलग्नक नहीं।'),
              style: text.bodySmall,
            ),
          for (final (i, id) in attachments.indexed)
            ActionRow(
              icon: AppIcons.image,
              title: '${tr('Attachment', 'संलग्नक')} ${i + 1}',
              subtitle: tr('Protected image', 'सुरक्षित चित्र'),
              trailing: editable
                  ? IconButton(
                      tooltip: tr('Remove', 'हटाएँ'),
                      icon: const AppIcon(AppIcons.x),
                      onPressed: busy
                          ? null
                          : () => setState(() => attachments.remove(id)),
                    )
                  : null,
              divider: i < attachments.length - 1,
              onTap: () => context.go(
                '/work/attachment/$id?title=${Uri.encodeComponent(tr('Report attachment', 'रिपोर्ट संलग्नक'))}',
              ),
            ),
          if (editable)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: busy || widget.offline ? null : attach,
                icon: const AppIcon(AppIcons.paperclip, size: 18),
                label: Text(tr('Attach image', 'चित्र जोड़ें')),
              ),
            ),
          if (editable && offlineDrafts)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await localSave();
                        clearDirty();
                        setState(() => stage = 'Saved locally');
                      }),
                icon: const AppIcon(AppIcons.smartphone, size: 18),
                label: Text(
                  tr(
                    'Save encrypted local draft',
                    'एन्क्रिप्टेड स्थानीय ड्राफ़्ट सहेजें',
                  ),
                ),
              ),
            ),
          if (report['status'] == 'approved' &&
              report['isSelf'] == true &&
              widget.data['settings']?['amendments'] == true) ...[
            SectionHeader(tr('Amendment', 'संशोधन')),
            AppTextField(
              label: tr('Reason for amendment', 'संशोधन का कारण'),
              controller: reason,
              minLines: 2,
              maxLines: 4,
            ),
            ActionButton(
              tr('Start amendment', 'संशोधन शुरू करें'),
              variant: ButtonVariant.secondary,
              onPressed: busy
                  ? null
                  : () => run(() async {
                      report = {
                        ...report,
                        ...await command('amend', {
                          'id': report['id'],
                          'expectedVersion': report['version'],
                          'reason': reason.text,
                        }),
                      };
                      setState(() {});
                    }),
            ),
          ],
          if (report['isSelf'] != true && report['status'] == 'submitted') ...[
            SectionHeader(
              tr('Your review', 'आपकी समीक्षा'),
              subtitle: tr(
                'Every decision needs a written reason',
                'हर निर्णय के लिए लिखित कारण आवश्यक',
              ),
            ),
            AppTextField(
              key: const ValueKey('dwr-reason'),
              label: tr('Reason for your decision', 'निर्णय का कारण'),
              controller: reason,
              minLines: 2,
              maxLines: 4,
            ),
            Row(
              children: [
                for (final d in ['comment', 'return', 'approve'].where(
                  (d) => (report['actions'] as List? ?? widget.caps).contains(
                    d == 'approve' ? 'dwr_review.approve' : 'dwr_review.review',
                  ),
                )) ...[
                  Expanded(
                    child: ActionButton(
                      d == 'approve'
                          ? tr('Approve', 'स्वीकारें')
                          : d == 'return'
                          ? tr('Send back', 'वापस भेजें')
                          : tr('Comment', 'टिप्पणी'),
                      icon: d == 'approve'
                          ? AppIcons.check
                          : d == 'return'
                          ? AppIcons.undo2
                          : AppIcons.messageSquareText,
                      variant: d == 'approve'
                          ? ButtonVariant.primary
                          : ButtonVariant.secondary,
                      onPressed: busy || widget.offline
                          ? null
                          : () => run(() async {
                              report = {
                                ...report,
                                ...await command('review', {
                                  'id': report['id'],
                                  'expectedVersion': report['version'],
                                  'decision': d,
                                  'reason': reason.text,
                                }),
                              };
                              setState(() => stage = report['status']);
                              if (context.mounted) {
                                showConfirmation(
                                  context,
                                  tr('Decision recorded', 'निर्णय दर्ज हुआ'),
                                );
                              }
                            }),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ],
          if ((report['history'] as List? ?? const []).isNotEmpty)
            ExpansionTile(
              title: Text(
                tr('Revision and decision history', 'संशोधन और निर्णय इतिहास'),
                style: text.titleSmall,
              ),
              children: [
                for (final (i, h) in (report['history'] as List).indexed)
                  TimelineRow(
                    time: formatTime(context, h['created_at']),
                    title:
                        '${historyLabel('${h['event']}')} · v${h['version']}',
                    subtitle: '${h['reason'] ?? ''}'.isEmpty
                        ? formatDay(
                            context,
                            parseInstant(
                              h['created_at'],
                            )?.toIso8601String().substring(0, 10),
                          )
                        : '${h['reason']}',
                    kind: h['event'] == 'approve'
                        ? TimelineKind.start
                        : h['event'] == 'return'
                        ? TimelineKind.pending
                        : TimelineKind.neutral,
                    first: i == 0,
                    last: i == (report['history'] as List).length - 1,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          const SizedBox(height: 12),
        ],
      ),
      bottom: !editable || stage == 'Submitted'
          ? null
          : ActionPanel(
              note: widget.offline
                  ? tr(
                      'Offline: drafts are kept on this device until you reconnect.',
                      'ऑफ़लाइन: कनेक्ट होने तक ड्राफ़्ट इस डिवाइस पर रहेंगे।',
                    )
                  : null,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        tr('Save draft', 'ड्राफ़्ट सहेजें'),
                        icon: AppIcons.save,
                        variant: ButtonVariant.secondary,
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                if (widget.offline) {
                                  await localSave();
                                  clearDirty();
                                  setState(() => stage = 'Saved locally');
                                } else {
                                  await save();
                                  setState(() => stage = 'Saved draft');
                                }
                              }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ActionButton(
                        tr('Submit DWR', 'DWR भेजें'),
                        icon: AppIcons.sendHorizontal,
                        busy: busy && stage == 'Submitting',
                        onPressed: canSubmit ? submit : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

String historyLabel(String event) => tr(
  const {
        'save': 'Saved',
        'submit': 'Sent for review',
        'approve': 'Approved',
        'return': 'Sent back',
        'comment': 'Comment',
        'amend': 'Amendment started',
        'create': 'Created',
        'prepare': 'Prepared from chat',
      }[event] ??
      event,
  const {
        'save': 'सहेजा',
        'submit': 'समीक्षा के लिए भेजा',
        'approve': 'स्वीकृत',
        'return': 'वापस भेजा',
        'comment': 'टिप्पणी',
        'amend': 'संशोधन शुरू',
        'create': 'बनाया',
        'prepare': 'चैट से तैयार',
      }[event] ??
      event,
);

class _ReadOnlyGroup extends StatelessWidget {
  const _ReadOnlyGroup({
    required this.label,
    required this.lines,
    this.statedValue,
  });
  final String label, lines;
  final dynamic statedValue;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = lines.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.titleSmall),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(
              statedValue == 'none'
                  ? tr('Explicitly none', 'स्पष्ट रूप से कुछ नहीं')
                  : tr('Not stated', 'नहीं बताया'),
              style: text.bodyMedium?.copyWith(
                color: AppTokens.of(context).textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTokens.of(context).text,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: text.bodyLarge)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
