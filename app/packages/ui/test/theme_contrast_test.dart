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
        (Colors.white, dark ? BrandConfig.placeholder.primaryDeep : BrandConfig.placeholder.primary),
      ]) {
        expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg on $bg');
      }
    });
  }

  test('AppColors.lerp interpolates instead of snapping', () {
    final dark = appColorsFor(BrandConfig.placeholder, true);
    final light = appColorsFor(BrandConfig.placeholder, false);
    final mid = dark.lerp(light, 0.5);
    expect(mid.canvas, isNot(dark.canvas));
    expect(mid.canvas, isNot(light.canvas));
  });
}
