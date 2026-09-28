import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'api.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';
import 'graphql/operations.graphql.dart';
import 'graphql/schema.graphql.dart';

const roleNames = {
  'super_admin': 'Super Admin',
  'admin': 'Admin',
  'hr': 'HR',
  'jr_hr': 'Jr. HR',
  'employee': 'Employee',
  'manager': 'Manager',
  'supervisor': 'Supervisor',
};
const scopeNames = {
  'own': 'Own records',
  'team': 'Assigned team',
  'site': 'Selected site',
  'organization': 'Organization reports',
};
String ruleExplanation(String rule) => rule.startsWith('template:')
    ? '${tr('Inherited from', 'विरासत')}: ${roleNames[rule.split(':').last] ?? rule}'
    : rule.startsWith('dependency:')
    ? '${tr('Requires', 'आवश्यक')}: ${rule.split(':').last}'
    : {
            'explicit_deny': tr('Explicit deny', 'स्पष्ट अस्वीकृति'),
            'user_site_allow': tr(
              'User allowance at this site',
              'इस साइट पर व्यक्तिगत अनुमति',
            ),
            'no_allow': tr('No matching allow', 'कोई अनुमति नहीं'),
            'module_disabled': tr('Module is disabled', 'मॉड्यूल बंद है'),
            'unauthorized_site': tr(
              'Inactive site membership',
              'निष्क्रिय साइट सदस्यता',
            ),
          }[rule] ??
          rule;

class AccessUsersPage extends ConsumerStatefulWidget {
  const AccessUsersPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<AccessUsersPage> createState() => _AccessUsersPageState();
}

class _AccessUsersPageState extends ConsumerState<AccessUsersPage> {
  String search = '';
  late Future<Query$AccessUsers> users;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    users = ref.read(apiProvider).capabilities(widget.scope).then((s) {
      if (!s.scope.capabilities.contains('access.view')) {
        throw ApiFailure(
          'FORBIDDEN',
          tr(
            'Access administration is restricted',
            'अनुमति प्रशासन प्रतिबंधित है',
          ),
        );
      }
      return ref.read(apiProvider).accessUsers(widget.scope, search);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return PageScaffold(
      title: tr('Users & module access', 'उपयोगकर्ता और अनुमति'),
      body: ListView(
        padding: Space.page,
        children: [
          Text(
            tr(
              'Select a person. Changes apply to the selected site.',
              'व्यक्ति चुनें। बदलाव चयनित साइट पर लागू होते हैं।',
            ),
            style: text.bodyMedium?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            decoration: InputDecoration(
              hintText: tr('Search users', 'उपयोगकर्ता खोजें'),
              prefixIcon: const AppIcon(AppIcons.search),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => setState(() {
              search = v;
              load();
            }),
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: users,
            builder: (context, s) {
              if (s.hasError) {
                return InlineError(s.error!, retry: () => setState(load));
              }
              if (!s.hasData) {
                return const LoadingState(
                  rows: 5,
                  header: false,
                  rowHeight: 60,
                );
              }
              final d = s.data!.accessUsers;
              return Column(
                children: [
                  if (d.users.isEmpty)
                    EmptyState(
                      title: tr(
                        'No matching users',
                        'कोई उपयोगकर्ता नहीं मिला',
                      ),
                      message: tr(
                        'Try a name or email address.',
                        'नाम या ईमेल से खोजें।',
                      ),
                      illustration: TinyKind.people,
                    ),
                  for (final (i, u) in d.users.indexed)
                    Column(
                      children: [
                        ListTile(
                          leading: Avatar(u.name, size: 42),
                          title: Text(u.name),
                          subtitle: Text(u.email),
                          trailing: u.protected
                              ? StatusPill(
                                  tr('Protected', 'सुरक्षित'),
                                  tone: StatusTone.info,
                                  icon: AppIcons.shieldCheck,
                                )
                              : AppIcon(
                                  AppIcons.chevronRight,
                                  color: t.textSecondary,
                                ),
                          onTap: () async {
                            await context.push('/work/access/${u.id}');
                            if (mounted) setState(load);
                          },
                        ),
                        if (i < d.users.length - 1) const Divider(),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'Up to 100 matching accounts. Search to narrow results.',
                      'अधिकतम 100 खाते। परिणाम कम करने के लिए खोजें।',
                    ),
                    style: text.bodySmall,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AccessEditorPage extends ConsumerStatefulWidget {
  const AccessEditorPage({
    super.key,
    required this.scope,
    required this.userId,
  });
  final SiteScope scope;
  final String userId;
  @override
  ConsumerState<AccessEditorPage> createState() => _AccessEditorPageState();
}

class _AccessEditorPageState extends ConsumerState<AccessEditorPage> {
  late final UnsavedWork unsaved;
  Query$UserAccess$userAccess? user;
  List<Input$AccessRuleInput> rules = [];
  List<Input$DelegationInput> delegations = [];
  String role = 'employee', moduleId = 'employees', search = '';
  bool active = true,
      busy = false,
      history = false,
      isSuper = false,
      canManage = false;
  Object? error;
  final reason = TextEditingController();
  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
    load();
  }

  @override
  void dispose() {
    unsaved.mark('access', '', false);
    reason.dispose();
    super.dispose();
  }

  void dirty() => ref
      .read(unsavedWorkProvider)
      .mark(
        'access',
        tr('Access changes', 'अनुमति बदलाव'),
        reason.text.isNotEmpty,
      );

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final list = (await api.accessUsers(widget.scope, '')).accessUsers;
      final u = (await api.userAccess(widget.scope, widget.userId)).userAccess;
      if (mounted) {
        setState(() {
          isSuper = list.isSuperAdmin;
          canManage = list.canManage;
          user = u;
          role = u.role;
          active = u.active;
          rules = u.rules
              .map(
                (r) => Input$AccessRuleInput(
                  key: r.key,
                  effect: r.effect,
                  scope: r.scope,
                ),
              )
              .toList();
          delegations = u.delegations
              .map((d) => Input$DelegationInput(key: d.key, scope: d.scope))
              .toList();
          reason.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool get locked =>
      !canManage ||
      (!isSuper &&
          (user?.protected == true || widget.userId == widget.scope.actorId));
  Input$AccessChangeInput get input => Input$AccessChangeInput(
    expectedVersion: user!.version,
    role: role,
    active: active,
    rules: rules,
    delegations: delegations,
    reason: reason.text.trim(),
  );
  void change(String key, {String? effect, String? recordScope}) {
    final old = rules.where((r) => r.key == key).firstOrNull;
    final baseline = user!.effective
        .where((r) => r.key == key)
        .firstOrNull
        ?.decision;
    final next = Input$AccessRuleInput(
      key: key,
      effect: effect ?? old?.effect ?? 'inherit',
      scope:
          recordScope ??
          old?.scope ??
          ([
                    'access',
                    'organization',
                    'site_settings',
                    'audit',
                  ].contains(key.split('.').first) ||
                  key == 'employees.create'
              ? 'site'
              : baseline?.scope ?? 'own'),
    );
    setState(
      () => rules = [
        ...rules.where((r) => r.key != key),
        if (next.effect != 'inherit') next,
      ],
    );
  }

  Future<void> preview() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final draft = input;
      final p =
          (await ref
                  .read(apiProvider)
                  .previewAccess(widget.scope, widget.userId, draft))
              .previewAccess;
      if (!mounted) return;
      final confirmed = await showAppSheet<bool>(
        context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            4,
            Space.gutter,
            Space.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Review access changes', 'अनुमति बदलाव समीक्षा'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '${user!.name} · v${p.version} · ${roleNames[role]} · ${active ? tr('Active', 'सक्रिय') : tr('Inactive', 'निष्क्रिय')}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(reason.text, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in p.changes)
                      KeyValueRow(
                        c.key,
                        '${c.before.allowed ? scopeNames[c.before.scope] : tr('Denied', 'अस्वीकृत')} → ${c.after.allowed ? scopeNames[c.after.scope] : tr('Denied', 'अस्वीकृत')}\n${ruleExplanation(c.after.rule)}',
                        selectable: false,
                      ),
                    if (p.changes.isEmpty)
                      Text(
                        tr(
                          'No effective differences. Configuration changes will still be audited.',
                          'प्रभावी बदलाव नहीं। सेटिंग बदलाव का ऑडिट होगा।',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              NoticeBanner(
                tr(
                  'Saving signs this person out on every device.',
                  'सहेजने पर यह व्यक्ति सभी उपकरणों से साइन आउट होगा।',
                ),
                tone: StatusTone.warning,
                icon: AppIcons.logOut,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  tr('Confirm access changes', 'अनुमति बदलाव सहेजें'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('Keep editing', 'संपादन जारी रखें')),
              ),
            ],
          ),
        ),
      );
      if (confirmed == true) {
        await ref
            .read(apiProvider)
            .saveAccess(widget.scope, widget.userId, draft);
        if (widget.userId == widget.scope.actorId) {
          await ref.read(apiProvider).clear();
          ref.read(apiProvider).invalidations.add('UNAUTHENTICATED');
          return;
        }
        await load();
        unsaved.mark('access', '', false);
        if (mounted) {
          showConfirmation(
            context,
            tr(
              'Access updated and sessions invalidated',
              'अनुमति अपडेट हुई और सत्र बंद हुए',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = user;
    final modules =
        ref.watch(capabilityProvider(widget.scope)).value?.scope.modules ??
        const <Query$SiteScope$scope$modules>[];
    final m =
        modules.where((m) => m.id == moduleId).firstOrNull ??
        modules.firstOrNull;
    final visible = modules
        .where(
          (m) => '${m.name} ${m.hindi}'.toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: tr('Review user access', 'उपयोगकर्ता अनुमति समीक्षा'),
      body: u == null
          ? ListView(
              padding: Space.page,
              children: [
                if (error != null)
                  InlineError(error!, retry: load)
                else
                  const LoadingState(rows: 4),
              ],
            )
          : FormPageBody(
              fields: [
                Row(
                  children: [
                    Avatar(u.name, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name, style: text.headlineSmall),
                          Text(u.email, style: text.bodySmall),
                          Text(
                            '${tr('Access version', 'अनुमति संस्करण')} ${u.version}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in u.sites)
                      StatusPill(
                        s.name,
                        tone: s.active
                            ? StatusTone.success
                            : StatusTone.neutral,
                        icon: s.active ? AppIcons.mapPin : AppIcons.mapPinOff,
                      ),
                  ],
                ),
                if (locked)
                  NoticeBanner(
                    tr(
                      'You can review this account but cannot change its permissions.',
                      'आप इस खाते को देख सकते हैं, इसकी अनुमति नहीं बदल सकते।',
                    ),
                    icon: AppIcons.lockKeyhole,
                  ),
                const SizedBox(height: 16),
                LabeledField(
                  label: tr('Role template', 'भूमिका टेम्पलेट'),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('role:$role'),
                    initialValue: role,
                    isExpanded: true,
                    items: roleNames.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            enabled: isSuper || e.key != 'super_admin',
                            child: Text(
                              tr(e.value, permissionHindi[e.key] ?? e.value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: locked ? null : (v) => setState(() => role = v!),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('Active at this site', 'इस साइट पर सक्रिय')),
                  value: active,
                  onChanged: locked ? null : (v) => setState(() => active = v),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(tr('Permissions', 'अनुमतियाँ')),
                      icon: const AppIcon(AppIcons.slidersHorizontal),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(tr('History', 'इतिहास')),
                      icon: const AppIcon(AppIcons.history),
                    ),
                  ],
                  selected: {history},
                  onSelectionChanged: (v) => setState(() => history = v.first),
                ),
                const SizedBox(height: 18),
                if (history) ...[
                  if (u.audit.isEmpty)
                    EmptyState(
                      title: tr('No changes yet', 'अभी कोई बदलाव नहीं'),
                      message: tr(
                        'Reviewed changes will appear here.',
                        'समीक्षित बदलाव यहाँ दिखेंगे।',
                      ),
                      illustration: TinyKind.clipboard,
                    ),
                  for (final a in u.audit)
                    ExpansionTile(
                      title: Text(a.reason, style: text.titleSmall),
                      subtitle: Text(
                        '${formatInstant(context, a.createdAt)} · v${a.version}',
                        style: text.bodySmall,
                      ),
                      children: [
                        for (final c in a.changes)
                          KeyValueRow(
                            c.key,
                            '${c.before.allowed ? tr('Allowed', 'अनुमत') : tr('Denied', 'अस्वीकृत')} → ${c.after.allowed ? tr('Allowed', 'अनुमत') : tr('Denied', 'अस्वीकृत')} · ${scopeNames[c.after.scope] ?? c.after.scope}',
                            selectable: false,
                          ),
                      ],
                    ),
                ] else ...[
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('Find a module', 'मॉड्यूल खोजें'),
                      prefixIcon: const AppIcon(AppIcons.search),
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: tr('Module', 'मॉड्यूल'),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('module:$moduleId:$search'),
                      initialValue: visible.any((v) => v.id == moduleId)
                          ? moduleId
                          : null,
                      isExpanded: true,
                      items: visible
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(
                                tr(m.name, m.hindi),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => moduleId = v!),
                    ),
                  ),
                  if (m != null) ...[
                    if (!m.available)
                      NoticeBanner(
                        tr(
                          'Phase ${m.phase} · Unreleased. Configuring access does not activate this feature.',
                          'चरण ${m.phase} · आगामी। अनुमति बदलने से सुविधा चालू नहीं होती।',
                        ),
                        tone: StatusTone.warning,
                      ),
                    Text(
                      tr(
                        'Actions require View at an equal or broader record scope.',
                        'कार्रवाइयों के लिए समान या व्यापक दायरे में देखने की अनुमति आवश्यक है।',
                      ),
                      style: text.bodySmall,
                    ),
                    if (m.dependencies.isNotEmpty)
                      Text(
                        '${tr('Dependencies', 'आवश्यक अनुमतियाँ')}: ${m.dependencies.join(', ')}',
                        style: text.bodySmall,
                      ),
                    ...[...m.actions, ...m.fields.map((f) => 'field.$f')].map(
                      (action) =>
                          permissionRow(context, '${m.id}.$action', action, m),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                AppTextField(
                  label: tr('Reason for changes', 'बदलाव का कारण'),
                  controller: reason,
                  enabled: !locked,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  help: tr(
                    'At least 8 characters. Recorded in the audit history.',
                    'कम से कम 8 अक्षर। ऑडिट इतिहास में दर्ज।',
                  ),
                  onChanged: (_) => setState(dirty),
                ),
                if (error != null) InlineError(error!, retry: load),
              ],
              actions: [
                ActionButton(
                  busy
                      ? tr('Checking…', 'जाँच हो रही है…')
                      : tr('Preview changes', 'बदलाव का पूर्वावलोकन'),
                  icon: AppIcons.clipboardCheck,
                  busy: busy,
                  onPressed: locked || busy || reason.text.trim().length < 8
                      ? null
                      : preview,
                ),
              ],
            ),
    );
  }

  Widget permissionRow(
    BuildContext context,
    String key,
    String action,
    Query$SiteScope$scope$modules module,
  ) {
    final rule = rules.where((r) => r.key == key).firstOrNull;
    final effective = user!.effective
        .where((r) => r.key == key)
        .firstOrNull
        ?.decision;
    final bound = delegations.where((d) => d.key == key).firstOrNull;
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.m),
          side: BorderSide(color: t.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(accessLabel(action), style: text.titleMedium),
                  ),
                  if (effective != null)
                    StatusPill(
                      effective.allowed
                          ? scopeNames[effective.scope] ?? effective.scope
                          : tr('Denied', 'अस्वीकृत'),
                      tone: effective.allowed
                          ? StatusTone.success
                          : StatusTone.neutral,
                    ),
                ],
              ),
              if (effective != null)
                Text(ruleExplanation(effective.rule), style: text.bodySmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('$key:${rule?.effect}'),
                      initialValue: rule?.effect ?? 'inherit',
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: tr('Override', 'बदलाव'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'inherit',
                          child: Text(tr('Inherit', 'विरासत')),
                        ),
                        DropdownMenuItem(
                          value: 'allow',
                          child: Text(tr('Allow', 'अनुमति')),
                        ),
                        DropdownMenuItem(
                          value: 'deny',
                          child: Text(tr('Deny', 'अस्वीकृत')),
                        ),
                      ],
                      onChanged: locked ? null : (v) => change(key, effect: v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('$key:${rule?.scope}:${effective?.scope}'),
                      initialValue: rule?.scope ?? effective?.scope ?? 'own',
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: tr('Record scope', 'रिकॉर्ड दायरा'),
                      ),
                      items: scopeNames.entries
                          .where(
                            (s) =>
                                s.key != 'organization' ||
                                ['reports', 'analytics'].contains(module.id),
                          )
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.key,
                              child: Text(
                                tr(s.value, permissionHindi[s.key] ?? s.value),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: locked || rule?.effect != 'allow'
                          ? null
                          : (v) => change(key, recordScope: v),
                    ),
                  ),
                ],
              ),
              if (isSuper) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr(
                      'May delegate this permission',
                      'यह अनुमति आगे दे सकते हैं',
                    ),
                  ),
                  value: bound != null,
                  onChanged: locked
                      ? null
                      : (v) => setState(
                          () => delegations = [
                            ...delegations.where((d) => d.key != key),
                            if (v == true)
                              Input$DelegationInput(key: key, scope: 'site'),
                          ],
                        ),
                ),
                if (bound != null)
                  DropdownButtonFormField<String>(
                    key: ValueKey('$key:delegate:${bound.scope}'),
                    initialValue: bound.scope,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr('Delegation limit', 'आगे देने की सीमा'),
                    ),
                    items: scopeNames.entries
                        .where((s) => s.key != 'organization')
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.key,
                            child: Text(
                              tr(s.value, permissionHindi[s.key] ?? s.value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(
                      () => delegations = delegations
                          .map(
                            (d) => d.key == key
                                ? Input$DelegationInput(key: key, scope: v!)
                                : d,
                          )
                          .toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
