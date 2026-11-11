import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import 'attribution.dart';
import 'desktop.dart';
import 'session.dart';
import 'social_native_stub.dart' if (dart.library.io) 'social_native_io.dart';

/// Providers the backend accepts on POST /v1/auth/social.
abstract final class SocialProviders {
  static const kakao = 'kakao';
  static const naver = 'naver';
  static const google = 'google';
  static const apple = 'apple';
  static const all = [kakao, naver, google, apple];
}

/// Obtains a provider access token from the native SDK (or a dev stub).
/// Returns null when the user cancels. Throws ApiException('provider_not_configured')
/// when the build has no SDK wired for this provider.
abstract class SocialSignIn {
  const SocialSignIn();
  String get provider;
  Future<String?> obtainToken(BuildContext context);
}

/// Dev stand-in: a stable random id per provider, so the same tester keeps the same account.
/// Only offered when the API base is local (see [socialSignInsFor]).
class DevSocialSignIn extends SocialSignIn {
  DevSocialSignIn(
    this.provider, {
    required FlutterSecureStorage storage,
    Random? random,
  }) : _storage = storage,
       _random = random ?? Random.secure();

  @override
  final String provider;
  final FlutterSecureStorage _storage;
  final Random _random;

  String get _key => 'social.dev.$provider';

  /// Reads or creates the persisted dev id. Storage errors fall back to a fresh id.
  Future<String> devToken() async {
    try {
      final existing = await _storage.read(key: _key);
      if (existing != null && existing.isNotEmpty) return 'dev:$existing';
    } catch (_) {
      // Keystore unavailable: a fresh id still lets the flow run.
    }
    final id = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    try {
      await _storage.write(key: _key, value: id);
    } catch (_) {
      // Not persisted: the next launch creates a new dev account.
    }
    return 'dev:$id';
  }

  @override
  Future<String?> obtainToken(BuildContext context) => devToken();
}

/// Used when a provider has no native SDK in this build (web, or a build without its keys).
class UnconfiguredSocialSignIn extends SocialSignIn {
  const UnconfiguredSocialSignIn(this.provider);
  @override
  final String provider;

  @override
  Future<String?> obtainToken(BuildContext context) async =>
      throw const ApiException(501, 'provider_not_configured');
}

/// Native keys, read at build time (--dart-define). Empty = not configured; that hides the provider.
abstract final class SocialKeys {
  static const kakaoNativeKey = String.fromEnvironment('KAKAO_NATIVE_KEY');
  static const naverClientId = String.fromEnvironment('NAVER_CLIENT_ID');
  /// Host of the https App Link / Universal Link that Naver redirects to (the server's DOMAIN).
  static const appLinkHost = String.fromEnvironment('APP_LINK_DOMAIN');
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const requested = String.fromEnvironment('SOCIAL_PROVIDERS');

  static const values = {
    'KAKAO_NATIVE_KEY': kakaoNativeKey,
    'NAVER_CLIENT_ID': naverClientId,
    'APP_LINK_DOMAIN': appLinkHost,
    'GOOGLE_SERVER_CLIENT_ID': googleServerClientId,
    'GOOGLE_IOS_CLIENT_ID': googleIosClientId,
  };
}

/// True when this OS can finish an https callback in ASWebAuthenticationSession (iOS 17.4+). Unknown version: https.
bool naverUsesAppLink({required bool ios, required String osVersion}) {
  if (!ios) return true;
  final m = RegExp(r'(\d+)\.(\d+)').firstMatch(osVersion);
  if (m == null) return true;
  final major = int.parse(m.group(1)!);
  final minor = int.parse(m.group(2)!);
  return major > 17 || (major == 17 && minor >= 4);
}

/// Which providers this build can offer. [requested] (SOCIAL_PROVIDERS, comma list) narrows the list;
/// empty means all. A provider is offered only when every key it needs is set. Apple needs no key.
Set<String> providersForKeys({
  required String requested,
  required Map<String, String> keys,
  required bool ios,
}) {
  bool has(String k) => (keys[k] ?? '').isNotEmpty;
  final wanted = requested.trim().isEmpty
      ? SocialProviders.all.toSet()
      : requested
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet();
  final available = {
    if (has('KAKAO_NATIVE_KEY')) SocialProviders.kakao,
    if (has('NAVER_CLIENT_ID') && has('APP_LINK_DOMAIN')) SocialProviders.naver,
    if (has('GOOGLE_SERVER_CLIENT_ID') && (!ios || has('GOOGLE_IOS_CLIENT_ID'))) SocialProviders.google,
    SocialProviders.apple,
  };
  return wanted.intersection(available);
}

/// The providers this build offers. Web and Windows have no native SDK here, so they offer none.
Set<String> configuredSocialProviders() {
  if (kIsWeb || isWindowsApp()) return {};
  return providersForKeys(
    requested: SocialKeys.requested,
    keys: SocialKeys.values,
    ios: defaultTargetPlatform == TargetPlatform.iOS,
  );
}

/// True for loopback / emulator / LAN-style dev hosts. Production hosts never get dev sign-in.
bool isDevApiBase(String baseUrl) {
  final host = Uri.tryParse(baseUrl)?.host ?? '';
  return host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '10.0.2.2' ||
      host.endsWith('.local');
}

/// Apple is offered where Sign in with Apple exists (iOS, macOS); never on the web.
bool appleAvailable() {
  // Web has no Sign in with Apple SDK wired: only the dev stubs appear there.
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Providers to show on a sign-in screen, in display order.
/// Dev base: every provider with a dev stub. Otherwise: configured providers only.
List<SocialSignIn> socialSignInsFor({
  required String apiBase,
  required FlutterSecureStorage storage,
  Set<String>? configured,
  bool? appleOk,
}) {
  final apple = appleOk ?? appleAvailable();
  final dev = isDevApiBase(apiBase);
  // Web has no social SDK wired yet, so production web shows no social buttons.
  final live = kIsWeb
      ? const <String>{}
      : (configured ?? configuredSocialProviders());
  final out = <SocialSignIn>[];
  for (final p in SocialProviders.all) {
    if (p == SocialProviders.apple && !apple) continue;
    if (dev) {
      out.add(DevSocialSignIn(p, storage: storage));
    } else if (live.contains(p)) {
      out.add(nativeSocialSignIn(p) ?? UnconfiguredSocialSignIn(p));
    }
  }
  return out;
}

/// Result of POST /v1/auth/social. Tokens are already saved to the session.
class SocialAuthResult {
  const SocialAuthResult({
    required this.isNew,
    required this.needsPhone,
    required this.role,
    required this.subject,
  });
  final bool isNew;
  final bool needsPhone;
  final String? role;
  final String? subject;

  factory SocialAuthResult.fromJson(Map<String, dynamic> j) => SocialAuthResult(
    isNew: j['is_new'] as bool? ?? false,
    needsPhone: j['needs_phone'] as bool? ?? false,
    role: j['role'] as String?,
    subject: j['subject'] as String?,
  );
}

/// Full social sign-in: SDK token, server exchange, session save. Null when the user cancelled.
Future<SocialAuthResult?> signInWithSocial({
  required BuildContext context,
  required ApiClient api,
  required Session session,
  required SocialSignIn provider,
  required String audience,
}) async {
  final token = await provider.obtainToken(context);
  if (token == null) return null;
  final body =
      await api.post('/auth/social', {
            'provider': provider.provider,
            'token': token,
            'audience': audience,
            'attribution': Attribution.get(),
          })
          as Map<String, dynamic>;
  await session.save(body);
  return SocialAuthResult.fromJson(body);
}

/// Attaches a verified phone to a social account. Customer and partner have separate routes.
String phoneAttachPath(String audience) =>
    audience == 'partner' ? '/partner/me/phone' : '/me/phone';

Future<void> attachPhone(
  ApiClient api, {
  required String audience,
  required String phone,
  required String code,
}) async {
  await api.post(phoneAttachPath(audience), {'phone': phone, 'code': code});
}

/// App-level default: the platform keystore for dev ids, the build-time provider list.
List<SocialSignIn> defaultSocialSignIns(String apiBase) =>
    socialSignInsFor(apiBase: apiBase, storage: const FlutterSecureStorage());
