import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import 'attribution.dart';

/// Staff second-factor step after the password. [enrol] means TOTP must be set up first (admins).
class StaffMfaChallenge {
  const StaffMfaChallenge({required this.enrol, required this.token});
  final bool enrol;
  final String token;
}

/// Who is signed in. Tokens live in the OS keystore (Keychain / Keystore / DPAPI).
/// Web: flutter_secure_storage has no keystore, so the refresh token sits in localStorage, encrypted
/// with a WebCrypto key kept in IndexedDB. Any script on the page can still read it while the tab is
/// open: the tradeoff is accepted for a no-install web app, guarded by the CSP in deploy/Caddyfile.
/// An httpOnly refresh cookie would be stronger but needs server work. logout() deletes it on web too.
class Session extends ChangeNotifier {
  Session({FlutterSecureStorage? storage, required this.namespace})
    : _storage = storage ?? const FlutterSecureStorage();

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
  /// [locale] is the app language, so the code SMS arrives in it.
  Future<String?> requestOtp(String phone, {String? locale}) async {
    final r =
        await api.post('/auth/otp', {'phone': phone, 'locale': ?locale})
            as Map<String, dynamic>;
    return r['dev_code'] as String?;
  }

  /// Returns true for a brand-new account (show the profile step).
  Future<bool> verifyOtp(
    String phone,
    String code, {
    required String audience,
  }) async {
    final r =
        await api.post('/auth/verify', {
              'phone': phone,
              'code': code,
              'audience': audience,
              'attribution': Attribution.get(),
            })
            as Map<String, dynamic>;
    await save(r);
    return r['is_new'] as bool? ?? false;
  }

  /// Password step. Returns the second factor the server wants (null once signed in).
  Future<StaffMfaChallenge?> staffLogin(String email, String password) async {
    final r =
        await api.post('/auth/staff/login', {
              'email': email,
              'password': password,
            })
            as Map<String, dynamic>;
    if (r['mfa_required'] == true || r['mfa_enrol_required'] == true) {
      return StaffMfaChallenge(
        enrol: r['mfa_enrol_required'] == true,
        token: r['mfa_token'] as String,
      );
    }
    await save(r);
    return null;
  }

  /// Second factor at sign-in: a TOTP [code] or one unused [recoveryCode]. Signs in on success.
  Future<void> staffMfaVerify(
    String token, {
    String? code,
    String? recoveryCode,
  }) async {
    await save(
      await api.post('/auth/staff/mfa/verify', {
            'mfa_token': token,
            'code': ?code,
            'recovery_code': ?recoveryCode,
          })
          as Map<String, dynamic>,
    );
  }

  /// Enrolment step 1: the TOTP secret and its otpauth URI (for a QR code or manual entry).
  Future<Map<String, dynamic>> staffMfaEnrolStart(String token) async =>
      await api.post('/auth/staff/mfa/enrol', {'mfa_token': token})
          as Map<String, dynamic>;

  /// Enrolment step 2: confirms the first code. Returns the tokens plus `recovery_codes` (shown once).
  /// Does not sign in: the caller saves the tokens after the owner has kept the codes.
  Future<Map<String, dynamic>> staffMfaEnrolConfirm(
    String token,
    String code,
  ) async =>
      await api.post('/auth/staff/mfa/enrol/confirm', {
            'mfa_token': token,
            'code': code,
          })
          as Map<String, dynamic>;

  /// Runs before local sign-out, while the access token still works (push token removal).
  Future<void> Function()? beforeLogout;

  Future<void> logout() async {
    final token = refreshToken;
    try {
      await beforeLogout?.call();
    } catch (_) {
      // Best-effort: a failed push unregister must never block signing out.
    }
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
  LocaleController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  Locale? locale;

  /// Every app language, named in its own language (one list for all pickers).
  // i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
  static const names = {'ko': '한국어', 'en': 'English'};
  static final supported = [for (final c in names.keys) Locale(c)];

  /// Stored value meaning "follow the device".
  static const _system = 'system';

  /// No choice yet follows the device (English stays English, every other device language reads Korean).
  /// A language archived after it was chosen reads English, and the stored choice is rewritten.
  Future<void> restore() async {
    final code = await _storage.read(key: 'app.locale').catchError((_) => null);
    if (code == null || code == _system) {
      locale = null;
    } else if (names.containsKey(code)) {
      locale = Locale(code);
    } else {
      locale = const Locale('en');
      await _storage.write(key: 'app.locale', value: 'en').catchError((_) {});
    }
    notifyListeners();
  }

  Future<void> set(Locale? value) async {
    locale = value;
    await _storage.write(
      key: 'app.locale',
      value: value?.languageCode ?? _system,
    );
    notifyListeners();
  }

  String get effectiveCode {
    final l = locale ?? PlatformDispatcher.instance.locale;
    return supported.any((s) => s.languageCode == l.languageCode)
        ? l.languageCode
        : 'ko';
  }
}
