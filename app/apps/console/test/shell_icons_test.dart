import 'package:console/shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  final pairs = navIconPairs();

  test('every nav item has its own registered rail icon', () {
    final ids = pairs.map((p) => p.$1).toList();
    expect(
      ids.toSet().length,
      ids.length,
      reason: 'two nav items share one icon id',
    );
    for (final (id, _) in pairs) {
      expect(Icon3DRegistry.has(id), isTrue, reason: id);
    }
  });

  test('each nav item shows the glyph its registry entry names', () {
    for (final (id, icon) in pairs) {
      expect(icon, Icon3DRegistry.of(id).icon, reason: id);
    }
  });

  test('first nav items keep their rail order', () {
    expect(pairs.take(3).map((p) => p.$1).toList(), [
      'c_dashboard',
      'c_bookings',
      'c_quotes',
    ]);
  });
}
