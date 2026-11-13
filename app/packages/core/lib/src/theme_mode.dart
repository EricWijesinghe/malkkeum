import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'gen/app_localizations.dart';

/// App-wide light / dark / system choice. [initial] applies until the user picks one: dark for
/// the staff apps, the phone's setting for the customer app (its design is drawn light).
class ThemeController extends ChangeNotifier {
  ThemeController({
    FlutterSecureStorage? storage,
    this.initial = ThemeMode.dark,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       mode = initial;

  final FlutterSecureStorage _storage;
  final ThemeMode initial;
  ThemeMode mode;

  static const _key = 'app.theme';

  Future<void> restore() async {
    final code = await _storage.read(key: _key).catchError((_) => null);
    mode = _parse(code) ?? initial;
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

  static ThemeMode? _parse(String? code) => switch (code) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    'dark' => ThemeMode.dark,
    _ => null,
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
