import 'dart:ui' show Color;

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
  // Chips and labels draw hue text on its own tint: tone on tint (light),
  // tint on darkTint (dark), matching the chip in basics.dart.
  final hues = <String, ServiceHue>{
    'studio': ServiceHues.studio,
    'kitchen': ServiceHues.kitchen,
    'bathroom': ServiceHues.bathroom,
    'mattress': ServiceHues.mattress,
    'aircon': ServiceHues.aircon,
    'sofa': ServiceHues.sofa,
    'move_out': ServiceHues.moveOut,
    'move_in': ServiceHues.moveIn,
    'consultation': StatusHues.consultation,
    'confirmed': StatusHues.confirmed,
    'assigned': StatusHues.assigned,
    'completed': StatusHues.completed,
    'cancelled': StatusHues.cancelled,
  };
  for (final e in hues.entries) {
    test('${e.key} tone passes 4.5:1 on light tint', () {
      expect(_ratio(e.value.tone, e.value.tint), greaterThanOrEqualTo(4.5));
    });
    test('${e.key} tint passes 4.5:1 on dark tint', () {
      expect(_ratio(e.value.tint, e.value.darkTint), greaterThanOrEqualTo(4.5));
    });
  }
}
