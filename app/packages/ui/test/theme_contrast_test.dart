import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final dark in [true, false]) {
    final name = dark ? 'dark' : 'light';
    test('$name text pairs meet WCAG AA (4.5:1)', () {
      final c = appColorsFor(BrandConfig.placeholder, dark);
      for (final (fg, bg) in [
        (c.ink, c.canvas),
        (c.ink, c.surface),
        (c.ink, c.surfaceHigh),
        (c.inkSoft, c.surface),
        (c.inkMuted, c.surface),
        (c.inkMuted, c.surfaceHigh),
        (c.danger, c.surface),
        (c.danger, c.canvas),
        (
          Colors.white,
          dark
              ? BrandConfig.placeholder.primaryDeep
              : BrandConfig.placeholder.primary,
        ),
        // Modern components: price pill, mint/primary tinted chips, gradient end.
        (c.ink, c.sunTint),
        (c.ink, c.freshTint),
        (c.ink, c.primaryTint),
        (c.inkMuted, c.surfaceHigh),
        (Colors.white, BrandConfig.placeholder.primaryDeep),
        (Colors.white, c.brandStart),
        (Colors.white, c.brandEnd),
      ]) {
        expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg on $bg');
      }
    });

    test('$name snackbar action, FAB and nav bar follow the design', () {
      final theme = buildTheme(
        BrandConfig.placeholder,
        dark ? Brightness.dark : Brightness.light,
      );
      final snack = theme.snackBarTheme;
      expect(
        _ratio(snack.actionTextColor!, snack.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
      final fab = theme.floatingActionButtonTheme;
      expect(
        _ratio(fab.foregroundColor!, fab.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
      expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
      expect(theme.appBarTheme.centerTitle, isFalse);
    });
  }

  // DAHAE-PLAN §1.1: brand pairs. Text >= 4.5:1, non-text (icons, borders, large text) >= 3:1.
  test('Dahae palette text pairs meet AA', () {
    const b = BrandConfig.placeholder;
    final l = appColorsFor(b, false);
    final d = appColorsFor(b, true);
    for (final (fg, bg, why) in [
      (b.primary, Colors.white, 'darkTeal links on white'),
      (b.primary, l.canvas, 'darkTeal on canvas'),
      (l.accent, l.surface, 'accent text'),
      (Colors.white, b.primary, 'primary button label'),
      (Colors.white, b.primaryDeep, 'pressed button label'),
      (b.ink, b.fresh, 'ink on teal fill'),
      (b.ink, b.sun, 'accent CTA label'),
      (
        StatusHues.confirmed.tone,
        StatusHues.confirmed.tint,
        'selected chip / confirmed',
      ),
      (
        StatusHues.consultation.tone,
        StatusHues.consultation.tint,
        'consultation status',
      ),
      (l.inkMuted, Colors.white, 'secondary text'),
      (l.inkMuted, l.canvas, 'secondary text on canvas'),
      (l.danger, Colors.white, 'error'),
      (d.accent, d.surface, 'dark accent text'),
      (d.accent, d.canvas, 'dark accent on canvas'),
      (d.canvas, d.accent, 'dark filled label on light teal'),
      (d.inkMuted, d.surfaceHigh, 'dark secondary'),
      (b.sun, d.surface, 'dark yellow accent'),
      (d.ink, d.primaryTint, 'dark ink on tint'),
    ]) {
      expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5), reason: why);
    }
  });

  test('teal is non-text only: >= 3:1 on white, but below body-text AA', () {
    const b = BrandConfig.placeholder;
    expect(_ratio(b.fresh, Colors.white), greaterThanOrEqualTo(3));
    expect(_ratio(b.fresh, Colors.white), lessThan(4.5));
    // Yellow on white is never text, and not even a usable border.
    expect(_ratio(b.sun, Colors.white), lessThan(3));
  });

  test('dark-mode primary pairs with its onPrimary label', () {
    for (final br in Brightness.values) {
      final s = buildTheme(BrandConfig.placeholder, br).colorScheme;
      expect(
        _ratio(s.onPrimary, s.primary),
        greaterThanOrEqualTo(4.5),
        reason: '$br',
      );
    }
  });

  test('AppColors.lerp interpolates instead of snapping', () {
    final dark = appColorsFor(BrandConfig.placeholder, true);
    final light = appColorsFor(BrandConfig.placeholder, false);
    final mid = dark.lerp(light, 0.5);
    expect(mid.canvas, isNot(dark.canvas));
    expect(mid.canvas, isNot(light.canvas));
  });
}
