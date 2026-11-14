import 'package:flutter/painting.dart';

/// WCAG AA threshold for body-size text and labels on a fill.
const minTextContrast = 4.5;

/// WCAG contrast ratio between two colours, 1.0 (none) to 21.0 (black on white).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// True when white label text on [fill] reads at AA. Brand colours must pass this.
bool whiteTextReadsOn(Color fill) =>
    contrastRatio(const Color(0xFFFFFFFF), fill) >= minTextContrast;
