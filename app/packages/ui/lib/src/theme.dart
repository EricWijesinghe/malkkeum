import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/motion.dart';
import 'tokens.dart';

/// Extra semantic colors the Material scheme has no slot for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceHigh,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.accent,
    required this.primaryTint,
    required this.fresh,
    required this.freshTint,
    required this.sun,
    required this.sunTint,
    required this.danger,
    required this.isDark,
  });

  final Color canvas;
  final Color surface;

  /// One step above [surface]: raised cards, input wells, snackbars in dark mode.
  final Color surfaceHigh;
  final Color line;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;

  /// Brand accent for glow and highlights. Not for text on the dark canvas.
  final Color accent;
  final Color primaryTint;
  final Color fresh;
  final Color freshTint;
  final Color sun;
  final Color sunTint;
  final Color danger;
  final bool isDark;

  Color tintOf(ServiceHue h) => isDark ? h.darkTint : h.tint;

  @override
  AppColors copyWith() => this;

  /// Real color interpolation so a theme switch crossfades instead of snapping.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      line: l(line, other.line),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      inkMuted: l(inkMuted, other.inkMuted),
      accent: l(accent, other.accent),
      primaryTint: l(primaryTint, other.primaryTint),
      fresh: l(fresh, other.fresh),
      freshTint: l(freshTint, other.freshTint),
      sun: l(sun, other.sun),
      sunTint: l(sunTint, other.sunTint),
      danger: l(danger, other.danger),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  Color get primary => Theme.of(this).colorScheme.primary;
}

const _font = 'Pretendard';
const _fallback = [
  'Apple SD Gothic Neo',
  'Noto Sans KR',
  'Noto Sans JP',
  'Noto Sans SC',
  'Noto Sans Sinhala',
  'Noto Sans Devanagari',
  'Noto Sans Thai',
  'Noto Sans Khmer',
  'Noto Sans Mongolian',
  'Malgun Gothic',
  'sans-serif',
];

TextTheme _type(Color ink, Color soft) {
  TextStyle s(
    double size,
    double height,
    FontWeight w, [
    Color? c,
    double ls = -0.2,
  ]) => TextStyle(
    fontFamily: _font,
    fontFamilyFallback: _fallback,
    package: 'ui',
    fontSize: size,
    height: height / size,
    fontWeight: w,
    letterSpacing: ls,
    color: c ?? ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  return TextTheme(
    displaySmall: s(32, 40, FontWeight.w800, null, -0.8),
    headlineMedium: s(26, 34, FontWeight.w800, null, -0.6),
    headlineSmall: s(22, 30, FontWeight.w700, null, -0.4),
    titleLarge: s(19, 26, FontWeight.w700, null, -0.3),
    titleMedium: s(17, 24, FontWeight.w600),
    titleSmall: s(15, 22, FontWeight.w600),
    bodyLarge: s(16, 24, FontWeight.w400),
    bodyMedium: s(15, 22, FontWeight.w400),
    bodySmall: s(13, 19, FontWeight.w400, soft, 0),
    labelLarge: s(16, 22, FontWeight.w600),
    labelMedium: s(13, 18, FontWeight.w600, null, 0),
    labelSmall: s(12, 16, FontWeight.w500, soft, 0),
  );
}

/// Dark = deep navy ink with lifted surfaces; light = white on mist.
AppColors appColorsFor(BrandConfig brand, bool dark) => AppColors(
  canvas: dark ? const Color(0xFF070B16) : Neutral.c50,
  surface: dark ? const Color(0xFF111829) : Colors.white,
  surfaceHigh: dark ? const Color(0xFF1A2339) : Neutral.c100,
  line: dark ? const Color(0xFF243050) : Neutral.c200,
  ink: dark ? const Color(0xFFF2F5FA) : Neutral.c900,
  inkSoft: dark ? const Color(0xFFC7CEDB) : Neutral.c700,
  inkMuted: dark ? const Color(0xFF9AA4B8) : Neutral.c500,
  accent: dark ? const Color(0xFF7C93FF) : brand.primary,
  primaryTint: dark ? const Color(0xFF1B2450) : const Color(0xFFEBEFFF),
  fresh: brand.fresh,
  freshTint: dark ? const Color(0xFF0F2F27) : const Color(0xFFDDF6EE),
  sun: brand.sun,
  sunTint: dark ? const Color(0xFF3A2D10) : const Color(0xFFFFF4D6),
  // Lighter red on dark surfaces so error text keeps WCAG AA contrast (4.5:1).
  danger: dark ? const Color(0xFFFF8A80) : Semantic.danger,
  isDark: dark,
);

ThemeData buildTheme(BrandConfig brand, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = appColorsFor(brand, dark);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brand.primary,
        brightness: brightness,
      ).copyWith(
        primary: dark ? colors.accent : brand.primary,
        onPrimary: Colors.white,
        surface: colors.surface,
        onSurface: colors.ink,
        error: colors.danger,
      );
  final text = _type(colors.ink, colors.inkMuted);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.input),
  );
  // White labels need the deeper brand fill in dark mode (accent 7C93FF fails 4.5:1 with white).
  final fill = dark ? brand.primary : scheme.primary;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.canvas,
    textTheme: text,
    fontFamily: _font,
    extensions: [colors],
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleMedium,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: shape,
        textStyle: text.labelLarge,
        disabledBackgroundColor: colors.line,
        disabledForegroundColor: colors.inkMuted,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        side: BorderSide(color: colors.line, width: 1.2),
        foregroundColor: colors.ink,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        textStyle: text.labelMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.input),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.input),
        borderSide: BorderSide(color: colors.danger, width: 1.2),
      ),
      hintStyle: text.bodyMedium?.copyWith(color: colors.inkMuted),
      labelStyle: text.bodyMedium?.copyWith(color: colors.inkMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      // Transparent so the GlassBar wrapping it shows through.
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primaryTint,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelSmall?.copyWith(
          color: s.contains(WidgetState.selected)
              ? colors.ink
              : colors.inkMuted,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? colors.surfaceHigh : Neutral.c900,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: dark ? colors.ink : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      side: BorderSide(color: colors.line),
      labelStyle: text.labelMedium,
      backgroundColor: colors.surface,
      selectedColor: colors.primaryTint,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        // iOS/macOS keep Cupertino for the edge-swipe back gesture.
        TargetPlatform.android: Depth3DPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: Depth3DPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: Depth3DPageTransitionsBuilder(),
      },
    ),
  );
}
