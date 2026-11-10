import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';

/// Who is signed in. Tokens live in the OS keystore (Keychain / Keystore / DPAPI).
class Session extends ChangeNotifier {
  Session({FlutterSecureStorage? storage, required this.namespace}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Keeps customer, partner and console sessions apart on the same device.
  final String namespace;
  ApiClient? _api;
  String? accessToken;
  String? refreshToken;
  String? role;
  String? subject;
  bool restored = false;

  bool get signedIn => refreshToken != null;
  ApiClient get api => _api!;

  void attach(ApiClient api) => _api = api;

  String _k(String key) => '$namespace.$key';

  Future<void> restore() async {
    try {
      refreshToken = await _storage.read(key: _k('refresh'));
      role = await _storage.read(key: _k('role'));
      subject = await _storage.read(key: _k('subject'));
    } catch (_) {
      // Keystore can be wiped (backup restore, OS reset): treat as signed out.
      refreshToken = null;
    }
    restored = true;
    notifyListeners();
  }

  Future<void> save(Map<String, dynamic> tokens) async {
    accessToken = tokens['access_token'] as String?;
    refreshToken = tokens['refresh_token'] as String?;
    role = tokens['role'] as String?;
    subject = tokens['subject'] as String?;
    await _storage.write(key: _k('refresh'), value: refreshToken);
    await _storage.write(key: _k('role'), value: role);
    await _storage.write(key: _k('subject'), value: subject);
    notifyListeners();
  }

  Future<void> clear() async {
    accessToken = refreshToken = role = subject = null;
    // Only this app's keys: other namespaces and the language setting stay.
    for (final k in ['refresh', 'role', 'subject']) {
      await _storage.delete(key: _k(k));
    }
    notifyListeners();
  }

  // --- flows -------------------------------------------------------------

  /// Returns the dev code when the server runs in DEV_MODE (local testing only).
  Future<String?> requestOtp(String phone) async {
    final r = await api.post('/auth/otp', {'phone': phone}) as Map<String, dynamic>;
    return r['dev_code'] as String?;
  }

  /// Returns true for a brand-new account (show the profile step).
  Future<bool> verifyOtp(String phone, String code, {required String audience}) async {
    final r = await api.post('/auth/verify', {'phone': phone, 'code': code, 'audience': audience}) as Map<String, dynamic>;
    await save(r);
    return r['is_new'] as bool? ?? false;
  }

  Future<void> staffLogin(String email, String password) async {
    await save(await api.post('/auth/staff/login', {'email': email, 'password': password}) as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final token = refreshToken;
    await clear();
    if (token != null) {
      try {
        await api.post('/auth/logout', {'refresh_token': token});
      } catch (_) {
        // Local sign-out already happened; the server token expires on its own.
      }
    }
  }
}

/// App language, persisted; null = follow the device.
class LocaleController extends ChangeNotifier {
  LocaleController({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  Locale? locale;

  static const supported = [Locale('ko'), Locale('en'), Locale('ja'), Locale('zh'), Locale('vi')];

  Future<void> restore() async {
    final code = await _storage.read(key: 'app.locale').catchError((_) => null);
    locale = code == null ? null : Locale(code);
    notifyListeners();
  }

  Future<void> set(Locale? value) async {
    locale = value;
    if (value == null) {
      await _storage.delete(key: 'app.locale');
    } else {
      await _storage.write(key: 'app.locale', value: value.languageCode);
    }
    notifyListeners();
  }

  String get effectiveCode {
    final l = locale ?? PlatformDispatcher.instance.locale;
    return supported.any((s) => s.languageCode == l.languageCode) ? l.languageCode : 'ko';
  }
}
