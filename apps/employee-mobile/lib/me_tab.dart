import 'ui/icons.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'app_router.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'push_notifications.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';
import 'graphql/operations.graphql.dart';

class MeTab extends ConsumerWidget {
  const MeTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(currentScopeProvider);
    if (scope == null) return TabRoot(child: _MeBody(scope: null));
    return TabRoot(
      child: _MeBody(key: ValueKey(scope), scope: scope),
    );
  }
}

class _MeBody extends ConsumerWidget {
  const _MeBody({super.key, required this.scope});
  final SiteScope? scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final caps = scope == null
        ? const <String>[]
        : (ref.watch(capabilityProvider(scope!)).value?.scope.capabilities ??
              const <String>[]);
    bool can(String k) => caps.contains(k);
    final profile = scope != null && can('my_hr.view')
        ? ref.watch(profileProvider(scope!))
        : null;
    final p = profile?.value?.myProfile;
    return PageScaffold(
      title: tr('Me', 'मैं'),
      body: ListView(
        padding: Space.page,
        children: [
          if (profile != null && profile.isLoading && p == null)
            const LoadingState(rows: 1, rowHeight: 80, header: false)
          else
            SurfaceCard(
              onTap: scope == null || !can('my_hr.view')
                  ? null
                  : () => context.go('/me/profile'),
              child: Row(
                children: [
                  Avatar(
                    p?.displayName ?? '?',
                    size: 56,
                    photo: p == null
                        ? null
                        : ref
                              .watch(
                                photoProvider((
                                  scope!,
                                  'employee/${p.id}',
                                  p.photoUpdatedAt,
                                )),
                              )
                              .value,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p?.displayName ??
                              tr('Your profile', 'आपकी प्रोफ़ाइल'),
                          style: text.titleLarge,
                        ),
                        if (p?.jobTitle != null)
                          Text(p!.jobTitle!, style: text.bodyMedium),
                        if (p != null)
                          Text(
                            [
                              p.employeeCode,
                              if (p.department != null) p.department!,
                            ].join(' · '),
                            style: text.bodySmall,
                          )
                        else if (scope == null)
                          Text(
                            tr(
                              'Choose a site to load your HR information.',
                              'एचआर जानकारी के लिए साइट चुनें।',
                            ),
                            style: text.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (scope != null && can('my_hr.view'))
                    AppIcon(AppIcons.chevronRight, color: t.textSecondary),
                ],
              ),
            ),
          SectionHeader(tr('Personal', 'व्यक्तिगत')),
          if (scope != null && can('my_hr.view'))
            ActionRow(
              icon: AppIcons.contactRound,
              title: tr('My Profile', 'मेरी प्रोफ़ाइल'),
              subtitle: tr(
                'HR information, employment and site assignments',
                'एचआर जानकारी, रोजगार और साइट नियुक्ति',
              ),
              onTap: () => context.go('/me/profile'),
            ),
          if (scope != null && (can('my_payroll.view') || can('payroll.view')))
            ActionRow(
              icon: AppIcons.receiptText,
              title: tr('My Salary', 'मेरा वेतन'),
              subtitle: tr(
                'Payslips and salary history',
                'वेतन पर्ची और वेतन इतिहास',
              ),
              onTap: () => context.go(recordRoute('payroll')),
            ),
          if (scope != null && can('my_documents.view')) ...[
            ActionRow(
              icon: AppIcons.fileText,
              title: tr('Documents', 'दस्तावेज़'),
              subtitle: tr(
                'Private documents and expiry reminders',
                'निजी दस्तावेज़ और समाप्ति अनुस्मारक',
              ),
              onTap: () => context.go(recordRoute('document')),
            ),
            ActionRow(
              icon: AppIcons.bookOpenCheck,
              title: tr('Policies', 'नीतियाँ'),
              subtitle: tr(
                'Published policies to read and acknowledge',
                'पढ़ने और स्वीकार करने की नीतियाँ',
              ),
              onTap: () => context.go(recordRoute('policy')),
            ),
          ],
          if (scope != null && can('assets.view'))
            ActionRow(
              icon: AppIcons.monitorSmartphone,
              title: tr('My Assets', 'मेरे उपकरण'),
              subtitle: tr(
                'Assigned equipment and returns',
                'सौंपे गए उपकरण और वापसी',
              ),
              onTap: () => context.go(recordRoute('asset')),
            ),
          if (scope != null && can('my_hr.view'))
            ActionRow(
              icon: AppIcons.history,
              title: tr('Employment history', 'रोजगार इतिहास'),
              subtitle: tr(
                'Joining, promotions, transfers',
                'नियुक्ति, पदोन्नति, स्थानांतरण',
              ),
              onTap: () => context.go(recordRoute('lifecycle')),
            ),
          if (scope != null &&
              !can('my_hr.view') &&
              !can('my_payroll.view') &&
              !can('my_documents.view') &&
              !can('assets.view'))
            EmptyState(
              title: tr(
                'Personal records are restricted',
                'व्यक्तिगत रिकॉर्ड प्रतिबंधित',
              ),
              message: tr(
                'Ask your administrator to review My HR information access.',
                'व्यवस्थापक से मेरी एचआर जानकारी की अनुमति जाँचने को कहें।',
              ),
              illustration: TinyKind.lock,
            ),
          SectionHeader(tr('App', 'ऐप')),
          ActionRow(
            icon: AppIcons.settings2,
            title: tr('Settings', 'सेटिंग'),
            subtitle: tr(
              'Language, appearance, notifications, offline outbox',
              'भाषा, रूप, सूचनाएँ, ऑफ़लाइन आउटबॉक्स',
            ),
            onTap: () => context.go('/me/settings'),
          ),
          const SizedBox(height: 20),
          ActionButton(
            tr('Sign out', 'साइन आउट'),
            icon: AppIcons.logOut,
            variant: ButtonVariant.secondary,
            onPressed: () => AppShellScope.of(context)?.signOut(),
          ),
          const SizedBox(height: 12),
          Text(
            tr(
              'Contact details are organization-wide. Assignments and operational history stay with their original site.',
              'संपर्क विवरण पूरे संगठन के हैं। नियुक्ति और कार्य इतिहास मूल साइट पर रहता है।',
            ),
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool showSensitive = false;
  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final caps =
        ref.watch(capabilityProvider(scope)).value?.scope.capabilities ??
        const <String>[];
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: tr('My Profile', 'मेरी प्रोफ़ाइल'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(profileProvider(scope)),
        child: ref
            .watch(profileProvider(scope))
            .when(
              loading: () => ListView(
                padding: Space.page,
                children: const [LoadingState(rows: 4)],
              ),
              error: (e, _) => ListView(
                padding: Space.page,
                children: [
                  InlineError(
                    e,
                    retry: () => ref.invalidate(profileProvider(scope)),
                  ),
                ],
              ),
              data: (data) {
                final p = data.myProfile;
                if (p == null) {
                  return ListView(
                    padding: Space.page,
                    children: [
                      EmptyState(
                        title: tr(
                          'No active employee profile',
                          'कोई सक्रिय कर्मचारी प्रोफ़ाइल नहीं',
                        ),
                        message: tr(
                          'Contact HR to check your dated site assignment.',
                          'अपनी साइट नियुक्ति जाँचने के लिए एचआर से संपर्क करें।',
                        ),
                        illustration: TinyKind.people,
                      ),
                    ],
                  );
                }
                final sensitive = [
                  p.salary,
                  p.bank,
                  p.identity,
                ].any((v) => v != null);
                final photo = ref
                    .watch(
                      photoProvider((
                        scope,
                        'employee/${p.id}',
                        p.photoUpdatedAt,
                      )),
                    )
                    .value;
                final pending = ref
                    .watch(requestsProvider(scope))
                    .value
                    ?.profileRequests
                    .where((r) => r.isSelf && r.status == 'pending')
                    .firstOrNull;
                return ListView(
                  padding: Space.page,
                  children: [
                    Row(
                      children: [
                        Avatar(p.displayName, size: 72, photo: photo),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.displayName, style: text.headlineSmall),
                              if (p.jobTitle != null)
                                Text(p.jobTitle!, style: text.bodyMedium),
                              if (p.department != null)
                                Text(p.department!, style: text.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SectionHeader(
                      tr('Contact', 'संपर्क'),
                      subtitle: tr(
                        'Organization-wide details',
                        'संगठन-स्तरीय विवरण',
                      ),
                    ),
                    KeyValueRow(
                      tr('Employee ID', 'कर्मचारी आईडी'),
                      p.employeeCode,
                    ),
                    if (p.workEmail != null)
                      KeyValueRow(tr('Work email', 'कार्य ईमेल'), p.workEmail!),
                    if (p.phone != null)
                      KeyValueRow(
                        tr('Phone number', 'फ़ोन नंबर'),
                        p.phone!.isEmpty
                            ? tr('Not recorded', 'दर्ज नहीं')
                            : p.phone!,
                      ),
                    if (p.permittedFields.contains('contact')) ...[
                      SectionHeader(tr('Basic details', 'मूल विवरण')),
                      ..._personalRows(context, p.personal),
                    ],
                    if (pending != null)
                      NoticeBanner(
                        tr(
                          'Your update from ${formatDay(context, pending.createdAt)} is waiting for HR review.',
                          '${formatDay(context, pending.createdAt)} का आपका अपडेट एचआर समीक्षा की प्रतीक्षा में है।',
                        ),
                        tone: StatusTone.warning,
                        icon: AppIcons.hourglass,
                      ),
                    if (caps.contains('my_hr.submit') &&
                        p.permittedFields.contains('contact')) ...[
                      const SizedBox(height: 6),
                      ActionButton(
                        tr('Update photo & details', 'फ़ोटो और विवरण बदलें'),
                        icon: AppIcons.pencil,
                        variant: ButtonVariant.secondary,
                        onPressed: pending != null
                            ? null
                            : () => context.go('/me/profile/request'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          'HR reviews your changes before they appear on your record.',
                          'आपके बदलाव रिकॉर्ड में आने से पहले एचआर उनकी समीक्षा करता है।',
                        ),
                        style: text.bodySmall,
                      ),
                    ],
                    SectionHeader(tr('Employment', 'रोजगार')),
                    for (final e in p.employment)
                      KeyValueRow(
                        tr('Legal employer', 'कानूनी नियोक्ता'),
                        '${e.legalEmployer.name}\n${formatDay(context, e.startsOn)} → ${e.endsOn == null ? tr('Current', 'वर्तमान') : formatDay(context, e.endsOn)}',
                      ),
                    if (p.permittedFields.contains('employment'))
                      _WorkDetails(scope: scope, employeeId: p.id),
                    if (sensitive) ...[
                      SectionHeader(
                        tr('Salary & identity', 'वेतन और पहचान'),
                        trailing: TextButton.icon(
                          onPressed: () =>
                              setState(() => showSensitive = !showSensitive),
                          icon: AppIcon(
                            showSensitive ? AppIcons.eyeOff : AppIcons.eye,
                            size: 18,
                          ),
                          label: Text(
                            showSensitive
                                ? tr('Hide', 'छिपाएँ')
                                : tr('Show', 'दिखाएँ'),
                          ),
                        ),
                      ),
                      if (p.salary != null)
                        KeyValueRow(
                          tr('Salary', 'वेतन'),
                          showSensitive ? p.salary! : '••••••',
                          selectable: showSensitive,
                        ),
                      if (p.bank != null)
                        KeyValueRow(
                          tr('Bank account', 'बैंक खाता'),
                          showSensitive ? p.bank! : '••••••',
                          selectable: showSensitive,
                        ),
                      if (p.identity != null)
                        KeyValueRow(
                          tr('Identity reference', 'पहचान संदर्भ'),
                          showSensitive ? p.identity! : '••••••',
                          selectable: showSensitive,
                        ),
                    ],
                    if (p.permittedFields.contains('employment') &&
                        p.assignments.isNotEmpty) ...[
                      SectionHeader(
                        tr('Site assignments', 'साइट नियुक्ति'),
                        subtitle: tr(
                          'Effective-dated; history stays with each site',
                          'तिथि-आधारित; इतिहास हर साइट पर रहता है',
                        ),
                      ),
                      for (final (i, a) in p.assignments.indexed)
                        TimelineRow(
                          title: a.site.name,
                          subtitle:
                              '${formatDay(context, a.startsOn)} → ${a.endsOn == null ? tr('Current', 'वर्तमान') : formatDay(context, a.endsOn)}',
                          kind: a.endsOn == null
                              ? TimelineKind.start
                              : TimelineKind.neutral,
                          first: i == 0,
                          last: i == p.assignments.length - 1,
                        ),
                    ],
                    const SizedBox(height: 12),
                    ActionRow(
                      icon: AppIcons.history,
                      title: tr('Employment history', 'रोजगार इतिहास'),
                      subtitle: tr(
                        'Joining, promotions, transfers and confirmations',
                        'नियुक्ति, पदोन्नति, स्थानांतरण और पुष्टि',
                      ),
                      divider: false,
                      onTap: () => context.go(recordRoute('lifecycle')),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _WorkDetails extends ConsumerStatefulWidget {
  const _WorkDetails({required this.scope, required this.employeeId});
  final SiteScope scope;
  final String employeeId;
  @override
  ConsumerState<_WorkDetails> createState() => _WorkDetailsState();
}

class _WorkDetailsState extends ConsumerState<_WorkDetails> {
  late Future<Query$EmployeeDetails> data;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => data = ref
      .read(apiProvider)
      .employeeDetails(widget.scope, widget.employeeId);
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: data,
    builder: (context, s) {
      if (s.hasError) {
        return InlineError(
          s.error!,
          retry: () => setState(load),
          compact: true,
        );
      }
      if (!s.hasData) {
        return const LoadingState(rows: 2, header: false, rowHeight: 48);
      }
      final d = s.data!.employeeDetails;
      return Column(
        children: [
          if (d.shift != null)
            KeyValueRow(
              tr('Assigned shift', 'नियुक्त शिफ्ट'),
              '${d.shift!.name} · ${d.shift!.startTime ?? ''}–${d.shift!.endTime ?? ''}',
            ),
          for (final r in d.reporting)
            KeyValueRow(
              tr('Reporting manager', 'रिपोर्टिंग प्रबंधक'),
              '${r.managerName}\n${formatDay(context, r.startsOn)} → ${r.endsOn == null ? tr('Current', 'वर्तमान') : formatDay(context, r.endsOn)}',
            ),
        ],
      );
    },
  );
}

const _genders = [
  ('female', 'Female', 'महिला'),
  ('male', 'Male', 'पुरुष'),
  ('other', 'Other', 'अन्य'),
  ('undisclosed', 'Prefer not to say', 'नहीं बताना'),
];
const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

String? genderLabel(String? v) =>
    [
      for (final (k, en, hi) in _genders)
        if (k == v) tr(en, hi),
    ].firstOrNull ??
    v;

/// Labelled basic details in display order: (key, label, value).
List<(String, String, String?)> personalEntries(Fragment$PersonalFields? d) => [
  ('dateOfBirth', tr('Date of birth', 'जन्म तिथि'), d?.dateOfBirth),
  ('gender', tr('Gender', 'लिंग'), genderLabel(d?.gender)),
  ('bloodGroup', tr('Blood group', 'रक्त समूह'), d?.bloodGroup),
  ('personalEmail', tr('Personal email', 'निजी ईमेल'), d?.personalEmail),
  ('address', tr('Current address', 'वर्तमान पता'), d?.address),
  (
    'permanentAddress',
    tr('Permanent address', 'स्थायी पता'),
    d?.permanentAddress,
  ),
  (
    'emergencyName',
    tr('Emergency contact', 'आपातकालीन संपर्क'),
    d?.emergencyName,
  ),
  ('emergencyRelation', tr('Relation', 'संबंध'), d?.emergencyRelation),
  (
    'emergencyPhone',
    tr('Emergency phone', 'आपातकालीन फ़ोन'),
    d?.emergencyPhone,
  ),
];

List<Widget> _personalRows(BuildContext context, Fragment$PersonalFields? d) {
  final rows = [
    for (final (k, label, v) in personalEntries(d))
      if (v != null)
        KeyValueRow(label, k == 'dateOfBirth' ? formatDay(context, v) : v),
  ];
  return rows.isNotEmpty
      ? rows
      : [
          Text(
            tr('Not added yet.', 'अभी नहीं जोड़ा गया।'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
}

/// Photo, phone and basic details proposed for HR review. Nothing on the
/// employee record changes before an independent reviewer approves.
class ProfileRequestPage extends ConsumerStatefulWidget {
  const ProfileRequestPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<ProfileRequestPage> createState() => _ProfileRequestPageState();
}

class _ProfileRequestPageState extends ConsumerState<ProfileRequestPage> {
  late final UnsavedWork unsaved;
  final form = GlobalKey<FormState>();
  final phone = TextEditingController(), reason = TextEditingController();
  final text = {
    for (final k in [
      'personalEmail',
      'address',
      'permanentAddress',
      'emergencyName',
      'emergencyRelation',
      'emergencyPhone',
    ])
      k: TextEditingController(),
  };
  String? dateOfBirth, gender, bloodGroup;
  Uint8List? photo;
  Fragment$EmployeeFields? profile;
  Map<String, String> initial = const {};
  bool busy = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
    ref.listenManual(profileProvider(widget.scope), (_, next) {
      final p = next.value?.myProfile;
      if (p == null || profile != null) return;
      final d = p.personal;
      setState(() {
        profile = p;
        phone.text = p.phone ?? '';
        dateOfBirth = d?.dateOfBirth;
        gender = d?.gender;
        bloodGroup = d?.bloodGroup;
        for (final (k, v) in [
          ('personalEmail', d?.personalEmail),
          ('address', d?.address),
          ('permanentAddress', d?.permanentAddress),
          ('emergencyName', d?.emergencyName),
          ('emergencyRelation', d?.emergencyRelation),
          ('emergencyPhone', d?.emergencyPhone),
        ]) {
          text[k]!.text = v ?? '';
        }
        initial = details();
      });
    }, fireImmediately: true);
  }

  /// The complete proposed set; empty values are left out.
  Map<String, String> details() => {
    'dateOfBirth': ?dateOfBirth,
    'gender': ?gender,
    'bloodGroup': ?bloodGroup,
    for (final e in text.entries)
      if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
  };

  bool get changed =>
      photo != null ||
      phone.text.trim() != (profile?.phone ?? '') ||
      !mapEquals(details(), initial);

  void dirty() {
    unsaved.mark(
      'profile-request',
      tr('Profile update', 'प्रोफ़ाइल अपडेट'),
      changed || reason.text.isNotEmpty,
    );
    setState(() {});
  }

  @override
  void dispose() {
    unsaved.mark('profile-request', '', false);
    phone.dispose();
    reason.dispose();
    for (final c in text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) return;
    photo = await file.readAsBytes();
    if (mounted) dirty();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final d = details();
    try {
      await ref.read(apiProvider).requestProfileChange(widget.scope, {
        'phone': phone.text.trim(),
        'expectedVersion': profile!.version,
        'reason': reason.text.trim(),
        if (!mapEquals(d, initial)) 'details': d,
        if (photo != null) 'photo': base64Encode(photo!),
      });
      ref.invalidate(requestsProvider(widget.scope));
      ref.invalidate(profileProvider(widget.scope));
      unsaved.mark('profile-request', '', false);
      if (mounted) {
        showConfirmation(
          context,
          tr('Sent to HR for review', 'समीक्षा के लिए एचआर को भेजा गया'),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String? optionalPhone(String? v) =>
      v == null ||
          v.trim().isEmpty ||
          RegExp(r'^[+0-9()\s-]{6,25}$').hasMatch(v.trim())
      ? null
      : tr('Enter a valid phone number', 'सही फ़ोन नंबर दर्ज करें');

  Widget field(
    String key,
    String label, {
    int maxLength = 100,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => AppTextField(
    label: label,
    controller: text[key],
    optional: true,
    maxLength: maxLength,
    minLines: maxLines > 1 ? 2 : null,
    maxLines: maxLines,
    keyboardType: keyboard,
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final p = profile;
    return PageScaffold(
      title: tr('Update profile', 'प्रोफ़ाइल अपडेट'),
      body: p == null
          ? ListView(
              padding: Space.page,
              children: const [LoadingState(rows: 4)],
            )
          : Form(
              key: form,
              onChanged: dirty,
              child: FormPageBody(
                fields: [
                  Row(
                    children: [
                      Avatar(
                        p.displayName,
                        size: 88,
                        photo:
                            photo ??
                            ref
                                .watch(
                                  photoProvider((
                                    widget.scope,
                                    'employee/${p.id}',
                                    p.photoUpdatedAt,
                                  )),
                                )
                                .value,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Profile photo', 'प्रोफ़ाइल फ़ोटो'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => pick(ImageSource.camera),
                                  icon: const AppIcon(
                                    AppIcons.camera,
                                    size: 18,
                                  ),
                                  label: Text(tr('Take photo', 'फ़ोटो लें')),
                                ),
                                TextButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => pick(ImageSource.gallery),
                                  icon: const AppIcon(AppIcons.image, size: 18),
                                  label: Text(tr('Choose', 'चुनें')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SectionHeader(tr('Contact', 'संपर्क')),
                  AppTextField(
                    label: tr('Phone number', 'फ़ोन नंबर'),
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 25,
                    validator: (v) =>
                        v != null && RegExp(r'^[+0-9()\s-]*$').hasMatch(v)
                        ? null
                        : tr(
                            'Enter a valid phone number',
                            'सही फ़ोन नंबर दर्ज करें',
                          ),
                  ),
                  field(
                    'personalEmail',
                    tr('Personal email', 'निजी ईमेल'),
                    maxLength: 254,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null ||
                            v.trim().isEmpty ||
                            RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(v.trim())
                        ? null
                        : tr('Enter a valid email', 'सही ईमेल दर्ज करें'),
                  ),
                  SectionHeader(tr('Basic details', 'मूल विवरण')),
                  DateField(
                    label: tr('Date of birth', 'जन्म तिथि'),
                    value: dateOfBirth,
                    optional: true,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    onChanged: (v) {
                      dateOfBirth = v;
                      dirty();
                    },
                  ),
                  ChoiceChips<String?>(
                    label: tr('Gender', 'लिंग'),
                    value: gender,
                    items: [
                      for (final (k, en, hi) in _genders) (k, tr(en, hi)),
                    ],
                    onChanged: (v) {
                      gender = v == gender ? null : v;
                      dirty();
                    },
                  ),
                  ChoiceChips<String?>(
                    label: tr('Blood group', 'रक्त समूह'),
                    value: bloodGroup,
                    items: [for (final b in _bloodGroups) (b, b)],
                    onChanged: (v) {
                      bloodGroup = v == bloodGroup ? null : v;
                      dirty();
                    },
                  ),
                  field(
                    'address',
                    tr('Current address', 'वर्तमान पता'),
                    maxLength: 300,
                    maxLines: 3,
                    keyboard: TextInputType.streetAddress,
                  ),
                  field(
                    'permanentAddress',
                    tr('Permanent address', 'स्थायी पता'),
                    maxLength: 300,
                    maxLines: 3,
                    keyboard: TextInputType.streetAddress,
                  ),
                  SectionHeader(tr('Emergency contact', 'आपातकालीन संपर्क')),
                  field('emergencyName', tr('Name', 'नाम')),
                  field(
                    'emergencyRelation',
                    tr('Relation', 'संबंध'),
                    maxLength: 50,
                  ),
                  field(
                    'emergencyPhone',
                    tr('Phone number', 'फ़ोन नंबर'),
                    maxLength: 25,
                    keyboard: TextInputType.phone,
                    validator: optionalPhone,
                  ),
                  SectionHeader(tr('For HR', 'एचआर के लिए')),
                  AppTextField(
                    label: tr('Note for HR', 'एचआर के लिए नोट'),
                    controller: reason,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    help: tr(
                      'Why you are updating (at least 8 characters)',
                      'बदलाव का कारण (कम से कम 8 अक्षर)',
                    ),
                    validator: (v) => (v?.trim().length ?? 0) >= 8
                        ? null
                        : tr(
                            'Use at least 8 characters',
                            'कम से कम 8 अक्षर लिखें',
                          ),
                  ),
                  Text(
                    tr(
                      'HR reviews your changes before they appear on your record. Employment, salary and bank details stay with HR.',
                      'आपके बदलाव रिकॉर्ड में आने से पहले एचआर समीक्षा करता है। रोजगार, वेतन और बैंक विवरण एचआर संभालता है।',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                  if (error != null) InlineError(error!),
                ],
                actions: [
                  ActionButton(
                    busy
                        ? tr('Sending…', 'भेजा जा रहा है…')
                        : tr('Send to HR for review', 'समीक्षा के लिए भेजें'),
                    busy: busy,
                    icon: AppIcons.sendHorizontal,
                    onPressed: busy || !changed ? null : submit,
                  ),
                ],
              ),
            ),
    );
  }
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? pushStatus;
  bool pushBusy = false;

  Future<void> enablePush() async {
    final scope = ref.read(currentScopeProvider);
    if (scope == null) return;
    setState(() => pushBusy = true);
    try {
      final status = await PushNotifications.instance.enable(
        ref.read(apiProvider),
        scope,
      );
      if (mounted) setState(() => pushStatus = status);
    } catch (_) {
      if (mounted) {
        setState(
          () => pushStatus = tr(
            'Push registration failed. Your inbox still works.',
            'पुश पंजीकरण विफल। आपका इनबॉक्स फिर भी काम करता है।',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => pushBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(currentScopeProvider);
    final runtime = ref.watch(operationRuntimeProvider);
    return ValueListenableBuilder<DisplaySettings>(
      valueListenable: displaySettings,
      builder: (context, prefs, _) => PageScaffold(
        title: tr('Settings', 'सेटिंग'),
        body: ListView(
          padding: Space.page,
          children: [
            SectionHeader(tr('Display', 'डिस्प्ले'), top: 4),
            ChoiceChips<String>(
              label: tr('Language', 'भाषा'),
              value: prefs.language,
              items: const [('en', 'English'), ('hi', 'हिन्दी')],
              onChanged: (v) => setDisplaySettings(language: v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Dark theme', 'डार्क थीम')),
              subtitle: Text(
                tr(
                  'Separate dark palette, same green accents',
                  'अलग डार्क पैलेट, वही पीले हाइलाइट',
                ),
              ),
              secondary: const AppIcon(AppIcons.moonStar),
              value: prefs.dark,
              onChanged: (v) => setDisplaySettings(dark: v),
            ),
            SectionHeader(tr('Notifications', 'सूचनाएँ')),
            Text(
              pushStatus ??
                  tr(
                    'Notifications turn on automatically after sign-in for payroll, tasks, attendance, leave, daily reports and HR updates. Your in-app inbox is always the complete record.',
                    'साइन इन के बाद वेतन, कार्य, उपस्थिति, छुट्टी, दैनिक रिपोर्ट और एचआर अपडेट की सूचनाएँ अपने आप चालू होती हैं। ऐप का इनबॉक्स हमेशा पूरा रिकॉर्ड है।',
                  ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            ActionButton(
              tr('Check notifications', 'सूचनाएँ जाँचें'),
              icon: AppIcons.bellRing,
              variant: ButtonVariant.secondary,
              busy: pushBusy,
              onPressed: scope == null || pushBusy ? null : enablePush,
            ),
            SectionHeader(tr('Offline', 'ऑफ़लाइन')),
            ListenableBuilder(
              listenable: runtime,
              builder: (context, _) {
                final pending = runtime.queue
                    .where(
                      (e) => !['accepted', 'rejected'].contains(e['state']),
                    )
                    .length;
                return ActionRow(
                  icon: AppIcons.lockKeyhole,
                  title: tr('Encrypted outbox', 'एन्क्रिप्टेड आउटबॉक्स'),
                  subtitle: pending == 0
                      ? tr('Nothing waiting to sync', 'सिंक के लिए कुछ नहीं')
                      : tr(
                          '$pending item(s) waiting to sync',
                          '$pending आइटम सिंक की प्रतीक्षा में',
                        ),
                  count: pending,
                  onTap: () => context.go('/me/outbox'),
                );
              },
            ),
            SectionHeader(tr('About', 'ऐप के बारे में')),
            KeyValueRow(
              tr('App', 'ऐप'),
              'Defence Garden Employee 0.1.0',
              selectable: false,
            ),
            Text(
              tr(
                'Access is assigned by your HR team. Your designation does not determine app permissions.',
                'अनुमति आपकी एचआर टीम देती है। आपका पदनाम ऐप की अनुमति तय नहीं करता।',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ActionButton(
              tr('Sign out', 'साइन आउट'),
              icon: AppIcons.logOut,
              variant: ButtonVariant.secondary,
              onPressed: () => AppShellScope.of(context)?.signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
