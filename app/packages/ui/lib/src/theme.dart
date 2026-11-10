import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Extra semantic colors the Material scheme has no slot for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
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
  final Color line;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
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

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => t < 0.5 ? this : (other as AppColors? ?? this);
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  Color get primary => Theme.of(this).colorScheme.primary;
}

const _font = 'Pretendard';
const _fallback = ['Apple SD Gothic Neo', 'Noto Sans KR', 'Noto Sans JP', 'Noto Sans SC', 'Malgun Gothic', 'sans-serif'];

TextTheme _type(Color ink, Color soft) {
  TextStyle s(double size, double height, FontWeight w, [Color? c, double ls = -0.2]) => TextStyle(
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

ThemeData buildTheme(BrandConfig brand, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = AppColors(
    canvas: dark ? const Color(0xFF0B0F17) : Neutral.c50,
    surface: dark ? const Color(0xFF151A24) : Colors.white,
    line: dark ? const Color(0xFF262D3A) : Neutral.c200,
    ink: dark ? const Color(0xFFF2F4F7) : Neutral.c900,
    inkSoft: dark ? const Color(0xFFC3C9D3) : Neutral.c700,
    inkMuted: dark ? const Color(0xFF98A1AE) : Neutral.c500,
    primaryTint: dark ? const Color(0xFF1B2450) : const Color(0xFFEBEFFF),
    fresh: brand.fresh,
    freshTint: dark ? const Color(0xFF0F2F27) : const Color(0xFFDDF6EE),
    sun: brand.sun,
    sunTint: dark ? const Color(0xFF3A2D10) : const Color(0xFFFFF4D6),
    danger: const Color(0xFFD92D20),
    isDark: dark,
  );
  final scheme = ColorScheme.fromSeed(seedColor: brand.primary, brightness: brightness).copyWith(
    primary: dark ? const Color(0xFF7C93FF) : brand.primary,
    onPrimary: Colors.white,
    surface: colors.surface,
    onSurface: colors.ink,
    error: colors.danger,
  );
  final text = _type(colors.ink, colors.inkMuted);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
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
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
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
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 44), textStyle: text.labelMedium)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1C2230) : Neutral.c100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.input), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.input), borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.input), borderSide: BorderSide(color: colors.danger, width: 1.2)),
      hintStyle: text.bodyMedium?.copyWith(color: colors.inkMuted),
      labelStyle: text.bodyMedium?.copyWith(color: colors.inkMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primaryTint,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => text.labelSmall?.copyWith(
            color: s.contains(WidgetState.selected) ? colors.ink : colors.inkMuted,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          )),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2A3140) : Neutral.c900,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
      side: BorderSide(color: colors.line),
      labelStyle: text.labelMedium,
      backgroundColor: colors.surface,
      selectedColor: colors.primaryTint,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
