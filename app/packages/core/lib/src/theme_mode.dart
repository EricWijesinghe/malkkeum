import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'gen/app_localizations.dart';

/// App-wide light / dark / system choice. Dark is the default: the brand is
/// designed dark-first and the system setting is opt-in.
class ThemeController extends ChangeNotifier {
  ThemeController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  ThemeMode mode = ThemeMode.dark;

  static const _key = 'app.theme';

  Future<void> restore() async {
    final code = await _storage.read(key: _key).catchError((_) => null);
    mode = _parse(code);
    notifyListeners();
  }

  Future<void> set(ThemeMode value) async {
    mode = value;
    notifyListeners();
    final code = _code(value);
    await _storage.write(key: _key, value: code).catchError((_) {});
  }

  /// dark -> light -> system -> dark, for one-tap toggles.
  Future<void> cycle() => set(switch (mode) {
    ThemeMode.dark => ThemeMode.light,
    ThemeMode.light => ThemeMode.system,
    ThemeMode.system => ThemeMode.dark,
  });

  static ThemeMode _parse(String? code) => switch (code) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  static String _code(ThemeMode m) => switch (m) {
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
    ThemeMode.dark => 'dark',
  };
}

extension ThemeModeLabels on T {
  String themeLabel(ThemeMode m) => switch (m) {
    ThemeMode.dark => themeDark,
    ThemeMode.light => themeLight,
    ThemeMode.system => themeSystem,
  };
}
