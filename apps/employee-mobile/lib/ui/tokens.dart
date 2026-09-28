import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

/// Design tokens for the employee app. Light and dark are separate palettes;
/// dark is not an inversion. The green accent always carries white text; its
/// pale tint always carries the primary charcoal text.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.accentPale,
    required this.onAccent,
    required this.outline,
    required this.control,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.info,
    required this.infoBg,
  });
  final Color canvas,
      surface,
      surfaceMuted,
      text,
      textSecondary,
      accent,
      accentLight,
      accentDark,
      accentPale,
      onAccent,
      outline,
      control,
      success,
      successBg,
      warning,
      warningBg,
      error,
      errorBg,
      info,
      infoBg;

  static const light = AppTokens(
    canvas: Color(0xFFF7F7F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEEEE7),
    text: Color(0xFF202421),
    textSecondary: Color(0xFF626860),
    accent: Color(0xFF1E6B4B),
    accentLight: Color(0xFF2F9467),
    accentDark: Color(0xFF124A33),
    accentPale: Color(0xFFE3EFE6),
    onAccent: Color(0xFFFFFFFF),
    outline: Color(0xFFE3E5DD),
    control: Color(0xFFC9CCC3),
    success: Color(0xFF137A44),
    successBg: Color(0xFFD5F0DE),
    warning: Color(0xFF9A5B00),
    warningBg: Color(0xFFFDEBCF),
    error: Color(0xFFB3261E),
    errorBg: Color(0xFFFADAD7),
    info: Color(0xFF2D5FA6),
    infoBg: Color(0xFFE0E9F8),
  );
  static const dark = AppTokens(
    canvas: Color(0xFF131513),
    surface: Color(0xFF1B1E1C),
    surfaceMuted: Color(0xFF272B29),
    text: Color(0xFFECEEE8),
    textSecondary: Color(0xFFB1B6AD),
    accent: Color(0xFF248056),
    accentLight: Color(0xFF2F9467),
    accentDark: Color(0xFF0F3D2B),
    accentPale: Color(0xFF16321F),
    onAccent: Color(0xFFFFFFFF),
    outline: Color(0xFF33383A),
    control: Color(0xFF4A5052),
    success: Color(0xFF86D6A8),
    successBg: Color(0xFF173726),
    warning: Color(0xFFF0BB6E),
    warningBg: Color(0xFF3D2D10),
    error: Color(0xFFF2B8B5),
    errorBg: Color(0xFF4B211D),
    info: Color(0xFFA7C6F4),
    infoBg: Color(0xFF1A2B45),
  );

  /// Light-to-dark green wash for focal areas (status card, net pay, brand
  /// mark, record button). Solid [accent] stays for buttons and the selected
  /// navigation indicator so their states remain predictable.
  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accentDark],
  );

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? light;

  @override
  AppTokens copyWith() => this;
  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) =>
      t < .5 ? this : (other as AppTokens? ?? this);
}

/// 4/8 spacing system.
abstract final class Space {
  static const double xs = 4,
      s = 8,
      m = 12,
      l = 16,
      xl = 20,
      xxl = 24,
      xxxl = 32;
  static const double gutter = 20;
  static const EdgeInsets page = EdgeInsets.fromLTRB(gutter, 8, gutter, 32);
}

abstract final class Radii {
  static const double s = 12, m = 16, l = 20, xl = 24;
}

/// Standard motion durations. Animations are skipped under reduced motion.
abstract final class Motion {
  static const short = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 240);
}

const _latin = 'Manrope';
const _fallback = ['NotoSansDevanagari'];

TextTheme _textTheme(AppTokens t) {
  TextStyle s(double size, FontWeight w, {double? height, Color? color}) =>
      TextStyle(
        fontFamily: _latin,
        fontFamilyFallback: _fallback,
        fontSize: size,
        fontWeight: w,
        height: height ?? 1.35,
        color: color ?? t.text,
      );
  return TextTheme(
    displaySmall: s(32, FontWeight.w700, height: 1.15),
    headlineMedium: s(26, FontWeight.w700, height: 1.2),
    headlineSmall: s(22, FontWeight.w700, height: 1.25),
    titleLarge: s(19, FontWeight.w600, height: 1.3),
    titleMedium: s(16, FontWeight.w600),
    titleSmall: s(14, FontWeight.w600),
    bodyLarge: s(16, FontWeight.w400, height: 1.45),
    bodyMedium: s(15, FontWeight.w400, height: 1.45),
    bodySmall: s(13, FontWeight.w400, color: t.textSecondary),
    labelLarge: s(15, FontWeight.w600),
    labelMedium: s(13, FontWeight.w500, color: t.textSecondary),
    labelSmall: s(12, FontWeight.w500, color: t.textSecondary),
  );
}

ThemeData buildEmployeeTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final t = dark ? AppTokens.dark : AppTokens.light;
  final text = _textTheme(t);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.accent,
    onPrimary: t.onAccent,
    primaryContainer: t.accentPale,
    onPrimaryContainer: t.text,
    secondary: t.text,
    onSecondary: t.surface,
    secondaryContainer: t.surfaceMuted,
    onSecondaryContainer: t.text,
    tertiary: t.info,
    onTertiary: t.surface,
    error: t.error,
    onError: dark ? t.canvas : t.surface,
    errorContainer: t.errorBg,
    onErrorContainer: t.error,
    surface: t.surface,
    onSurface: t.text,
    onSurfaceVariant: t.textSecondary,
    surfaceContainerHighest: t.surfaceMuted,
    surfaceContainerHigh: t.surfaceMuted,
    surfaceContainer: t.surface,
    surfaceContainerLow: t.surface,
    surfaceContainerLowest: t.surface,
    surfaceTint: Colors.transparent,
    outline: t.control,
    outlineVariant: t.outline,
    inverseSurface: t.text,
    onInverseSurface: t.canvas,
    shadow: Colors.black,
    scrim: Colors.black,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.m),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [t],
    fontFamily: _latin,
    textTheme: text,
    scaffoldBackgroundColor: t.canvas,
    canvasColor: t.canvas,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ReducedMotionTransitions(
          FadeForwardsPageTransitionsBuilder(),
        ),
        TargetPlatform.iOS: ReducedMotionTransitions(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.macOS: ReducedMotionTransitions(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.windows: ReducedMotionTransitions(
          FadeForwardsPageTransitionsBuilder(),
        ),
        TargetPlatform.linux: ReducedMotionTransitions(
          FadeForwardsPageTransitionsBuilder(),
        ),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: t.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      toolbarHeight: 60,
      titleTextStyle: text.titleMedium?.copyWith(fontSize: 17),
      iconTheme: IconThemeData(color: t.text, size: 24),
    ),
    iconTheme: IconThemeData(color: t.text, size: 22),
    dividerTheme: DividerThemeData(color: t.outline, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.l),
        side: BorderSide(color: t.outline),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      iconColor: t.text,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: text.bodySmall,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: text.bodyMedium?.copyWith(color: t.textSecondary),
      labelStyle: text.bodyMedium?.copyWith(color: t.textSecondary),
      floatingLabelStyle: text.labelMedium?.copyWith(color: t.textSecondary),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall?.copyWith(color: t.error),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.control),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.text, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.error, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        disabledBackgroundColor: t.surfaceMuted,
        disabledForegroundColor: t.textSecondary,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: text.labelLarge,
        shape: rounded,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        disabledForegroundColor: t.textSecondary,
        side: BorderSide(color: t.control, width: 1.5),
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: text.labelLarge,
        shape: rounded,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.text,
        disabledForegroundColor: t.textSecondary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: text.labelLarge,
        shape: rounded,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: t.text,
        minimumSize: const Size(48, 48),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: t.text,
        selectedForegroundColor: t.text,
        selectedBackgroundColor: t.accentPale,
        backgroundColor: t.surface,
        side: BorderSide(color: t.control),
        textStyle: text.labelMedium?.copyWith(color: t.text),
        minimumSize: const Size(48, 44),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.surface,
      selectedColor: t.accentPale,
      side: BorderSide(color: t.control),
      labelStyle: text.labelMedium?.copyWith(color: t.text),
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.accent,
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? t.onAccent
              : t.textSecondary,
          size: 24,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall!.copyWith(
          color: states.contains(WidgetState.selected)
              ? t.text
              : t.textSecondary,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: t.control,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.text,
      contentTextStyle: text.bodyMedium?.copyWith(color: t.canvas),
      actionTextColor: AppTokens.dark.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.s),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.text,
      linearTrackColor: t.surfaceMuted,
      circularTrackColor: t.surfaceMuted,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.onAccent : t.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accent : t.surfaceMuted,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accent : t.control,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accent : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(t.onAccent),
      side: BorderSide(color: t.control, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(t.text)),
    badgeTheme: BadgeThemeData(
      backgroundColor: t.text,
      textColor: t.canvas,
      textStyle: text.labelSmall?.copyWith(color: t.canvas, fontSize: 11),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.text,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: text.bodySmall?.copyWith(color: t.canvas),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      iconColor: t.text,
      collapsedIconColor: t.text,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(textStyle: text.bodyMedium),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: t.accentPale,
      headerForegroundColor: t.text,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
    ),
  );
}

class ReducedMotionTransitions extends PageTransitionsBuilder {
  const ReducedMotionTransitions(this.standard);
  final PageTransitionsBuilder standard;
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return standard.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
