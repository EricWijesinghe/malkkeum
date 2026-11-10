import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeController defaults to dark before anything is stored', () {
    expect(ThemeController().mode, ThemeMode.dark);
  });

  test('restore falls back to dark when secure storage is unavailable', () async {
    final c = ThemeController();
    await c.restore();
    expect(c.mode, ThemeMode.dark);
  });

  test('cycle goes dark -> light -> system -> dark', () async {
    final c = ThemeController()..mode = ThemeMode.dark;
    final seen = <ThemeMode>[];
    for (var i = 0; i < 3; i++) {
      await c.cycle();
      seen.add(c.mode);
    }
    expect(seen, [ThemeMode.light, ThemeMode.system, ThemeMode.dark]);
  });
}
