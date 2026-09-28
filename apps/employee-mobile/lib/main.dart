import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_router.dart' as app;
import 'mobile_ui.dart';
import 'providers.dart';
import 'ui/components.dart';
import 'workspace.dart';

export 'app_router.dart' show router;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerIconLicense();
  await loadDisplaySettings();
  runApp(const ProviderScope(child: EmployeeApp()));
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<DisplaySettings>(
    valueListenable: displaySettings,
    builder: (context, prefs, _) => MaterialApp.router(
      title: 'Defence Garden',
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      routerConfig: app.router,
      locale: Locale(prefs.language),
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: employeeTheme(Brightness.light),
      darkTheme: employeeTheme(Brightness.dark),
      themeMode: prefs.dark ? ThemeMode.dark : ThemeMode.light,
    ),
  );
}

/// Company mark: a leaf in a green gradient circle. Original, not a phone frame.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: t.accentGradient,
        shape: BoxShape.circle,
      ),
      child: AppIcon(AppIcons.sprout, size: size * .55, color: t.onAccent),
    );
  }
}

class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({super.key});
  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final restored = await ref.read(apiProvider).restore();
      // A restored session may belong to a different account than the last
      // one on this device: drop every cached value before entering the shell.
      ref.read(workspaceProvider.notifier).reset();
      ref.invalidate(bootstrapProvider);
      if (mounted) context.go(restored ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 72),
          const SizedBox(height: 20),
          Text('Defence Garden', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            authText('Restoring your session…'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    ),
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      code = TextEditingController();
  bool busy = false, mfa = false, enrollment = false, showPassword = false;
  String? secret, error, notice;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    final api = ref.read(apiProvider);
    try {
      if (mfa) {
        await api.post('/auth/mfa/verify', {'code': code.text});
        ref.read(workspaceProvider.notifier).reset();
        ref.invalidate(bootstrapProvider);
        if (mounted) context.go('/home');
      } else {
        final result = await api.login(email.text.trim(), password.text);
        password.clear();
        if (result['mfaRequired'] == true) {
          enrollment = result['enrollmentRequired'] == true;
          if (enrollment) {
            secret =
                (await api.post('/auth/mfa/setup', {}))['secret'] as String;
          }
          if (mounted) setState(() => mfa = true);
        } else if (mounted) {
          ref.read(workspaceProvider.notifier).reset();
          ref.invalidate(bootstrapProvider);
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recover() async {
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      final result = await ref.read(apiProvider).post('/auth/recovery', {
        'email': email.text.trim(),
      });
      if (mounted) setState(() => notice = result['message'] as String);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.canvas,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final wide = viewport.maxWidth >= 760;
          return SafeArea(
            child: Stack(
              children: [
                if (!wide)
                  const Positioned.fill(
                    bottom: null,
                    child: SizedBox(
                      height: 286,
                      child: _LoginHero(compact: true),
                    ),
                  ),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : Space.gutter,
                    wide ? 28 : 14,
                    wide ? 32 : Space.gutter,
                    28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(
                        children: [
                          _LoginUtilities(compact: !wide),
                          SizedBox(height: wide ? 24 : 92),
                          if (wide)
                            Container(
                              constraints: const BoxConstraints(minHeight: 650),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: tokens.surface,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: tokens.outline),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .08),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Expanded(child: _LoginHero()),
                                    Expanded(
                                      child: _buildForm(context, wide: true),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: tokens.surface,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: tokens.outline),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .10),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: _buildForm(context),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, {bool wide = false}) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 52 : 22,
        vertical: wide ? 54 : 30,
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!wide) ...[
                Row(
                  children: [
                    const _LoginBrandMark(size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Defence Garden', style: text.titleMedium),
                          Text(
                            tr('PEOPLE & HR', 'पीपल एंड एचआर'),
                            style: text.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
              Text(
                mfa
                    ? authText('Two-step verification')
                    : authText('Welcome back'),
                style: text.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                mfa
                    ? authText('Use your authenticator to continue.')
                    : authText('Sign in to Defence Garden Employee.'),
                style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: 30),
              if (!mfa) ...[
                AppTextField(
                  key: const ValueKey('login-email'),
                  label: authText('Email ID'),
                  hint: 'name@company.com',
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  prefix: const AppIcon(AppIcons.atSign, size: 21),
                ),
                AppTextField(
                  key: const ValueKey('login-password'),
                  label: authText('Password'),
                  hint: tr('Enter your password', 'अपना पासवर्ड दर्ज करें'),
                  controller: password,
                  obscureText: !showPassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  prefix: const AppIcon(AppIcons.lockKeyhole, size: 21),
                  onSubmitted: (_) => busy ? null : submit(),
                  suffix: IconButton(
                    tooltip: showPassword
                        ? tr('Hide password', 'पासवर्ड छिपाएँ')
                        : tr('Show password', 'पासवर्ड दिखाएँ'),
                    icon: AppIcon(
                      showPassword ? AppIcons.eyeOff : AppIcons.eye,
                    ),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.accentPale,
                    borderRadius: BorderRadius.circular(Radii.m),
                  ),
                  child: Row(
                    children: [
                      AppIcon(AppIcons.shieldCheck, color: tokens.text),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          email.text,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (secret != null) ...[
                  Text(
                    authText('Add this key to your authenticator:'),
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      secret!,
                      style: text.bodyLarge?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                AppTextField(
                  key: const ValueKey('login-code'),
                  label: authText('Six-digit code'),
                  hint: '000000',
                  controller: code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  prefix: const AppIcon(AppIcons.keyRound, size: 21),
                  onSubmitted: (_) => busy ? null : submit(),
                ),
              ],
              if (notice != null)
                NoticeBanner(notice!, icon: AppIcons.mailCheck),
              if (error != null) InlineError(error!),
              const SizedBox(height: 10),
              ActionButton(
                busy
                    ? authText('Please wait…')
                    : mfa
                    ? authText('Verify')
                    : authText('Sign in'),
                icon: mfa ? AppIcons.badgeCheck : AppIcons.arrowRight,
                busy: busy,
                onPressed: busy ? null : submit,
              ),
              if (!mfa)
                TextButton(
                  onPressed: busy ? null : recover,
                  child: Text(authText('Forgot your password?')),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    AppIcons.shield,
                    size: 17,
                    color: tokens.textSecondary,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      tr('Secure, authorized access', 'सुरक्षित, अधिकृत पहुँच'),
                      textAlign: TextAlign.center,
                      style: text.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                authText(
                  'Access is assigned by your HR team. Your designation does not determine app permissions.',
                ),
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginUtilities extends StatelessWidget {
  const _LoginUtilities({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final onDark = compact;
    final foreground = onDark ? Colors.white : AppTokens.of(context).text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _LoginUtilityButton(
          tooltip: tr('Language', 'भाषा'),
          label: displaySettings.value.language == 'en' ? 'EN' : 'हि',
          icon: AppIcons.languages,
          foreground: foreground,
          onPressed: () => setDisplaySettings(
            language: displaySettings.value.language == 'en' ? 'hi' : 'en',
          ),
        ),
        const SizedBox(width: 8),
        _LoginUtilityButton(
          tooltip: tr('Theme', 'थीम'),
          icon: displaySettings.value.dark ? AppIcons.sun : AppIcons.moonStar,
          foreground: foreground,
          onPressed: () =>
              setDisplaySettings(dark: !displaySettings.value.dark),
        ),
      ],
    );
  }
}

class _LoginUtilityButton extends StatelessWidget {
  const _LoginUtilityButton({
    required this.tooltip,
    required this.icon,
    required this.foreground,
    required this.onPressed,
    this.label,
  });
  final String tooltip;
  final String? label;
  final IconData icon;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: Material(
      color: foreground.withValues(alpha: .08),
      shape: StadiumBorder(
        side: BorderSide(color: foreground.withValues(alpha: .20)),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(icon, size: 20, color: foreground),
                if (label != null) ...[
                  const SizedBox(width: 7),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LoginBrandMark extends StatelessWidget {
  const _LoginBrandMark({this.size = 58});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AppTokens.of(context).accentGradient,
      borderRadius: BorderRadius.circular(size * .30),
    ),
    child: AppIcon(AppIcons.leaf, size: size * .54, color: Colors.white),
  );
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C5C42), Color(0xFF0D3226)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 48,
          compact ? 24 : 54,
          compact ? 20 : 44,
          compact ? 58 : 48,
        ),
        child: Column(
          mainAxisAlignment: compact
              ? MainAxisAlignment.start
              : MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LoginBrandMark(size: compact ? 48 : 60),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Defence Garden',
                      style: text.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      tr('PEOPLE & HR', 'पीपल एंड एचआर'),
                      style: text.labelSmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!compact) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      'Your workday,\nall in one place.',
                      'आपका कार्यदिवस,\nएक ही जगह।',
                    ),
                    style: text.displaySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr(
                      'Attendance, daily reports, leave and HR services—available according to your access.',
                      'उपस्थिति, दैनिक रिपोर्ट, छुट्टी और एचआर सेवाएँ—आपकी अनुमति के अनुसार उपलब्ध।',
                    ),
                    style: text.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: .76),
                      height: 1.55,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroFeature(
                    icon: AppIcons.lockKeyhole,
                    label: tr('Protected', 'सुरक्षित'),
                  ),
                  _HeroFeature(
                    icon: AppIcons.languages,
                    label: tr('Hindi + English', 'हिंदी + अंग्रेज़ी'),
                  ),
                  _HeroFeature(
                    icon: AppIcons.refreshCw,
                    label: tr('Offline ready', 'ऑफ़लाइन तैयार'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 17, color: const Color(0xFF8FD9B4)),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
