import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api.dart';
import 'social_auth.dart';

/// Naver returns the code to an https App Link / Universal Link, so no other app can receive it.
/// Register `https://<APP_LINK_DOMAIN>/auth/naver/callback` as the Naver callback URL.
const _naverPath = '/auth/naver/callback';

/// shortcut: iOS below 17.4 cannot finish an https callback, so it keeps the custom scheme (interceptable by another app). Drop when min iOS is 17.4.
const _naverLegacyScheme = 'malkkeumnaver';

/// Native SDK for each provider. Returns what the backend verifies (backend/crates/api/src/providers/social.rs):
/// Kakao: access token. Naver: `code:state` (server redeems it). Google: ID token. Apple: identity token.
SocialSignIn? nativeSocialSignIn(String provider) => switch (provider) {
  SocialProviders.kakao => const KakaoSocialSignIn(),
  SocialProviders.naver => const NaverSocialSignIn(),
  SocialProviders.google => const GoogleSocialSignIn(),
  SocialProviders.apple => const AppleSocialSignIn(),
  _ => null,
};

bool _kakaoReady = false;

class KakaoSocialSignIn extends SocialSignIn {
  const KakaoSocialSignIn();
  @override
  String get provider => SocialProviders.kakao;

  @override
  Future<String?> obtainToken(BuildContext context) async {
    if (!_kakaoReady) {
      await KakaoSdk.init(nativeAppKey: SocialKeys.kakaoNativeKey);
      _kakaoReady = true;
    }
    try {
      final token = await isKakaoTalkInstalled()
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      return token.accessToken;
    } on KakaoAuthException catch (e) {
      if (e.error == AuthErrorCause.accessDenied) return null;
      rethrow;
    }
  }
}

class NaverSocialSignIn extends SocialSignIn {
  const NaverSocialSignIn();
  @override
  String get provider => SocialProviders.naver;

  /// Browser login with a one-time code. The server redeems the code with our client secret, so the
  /// token is provably ours; the secret never ships in the app.
  @override
  Future<String?> obtainToken(BuildContext context) async {
    final state = _naverState();
    final appLink = naverUsesAppLink(
      ios: Platform.isIOS,
      osVersion: Platform.operatingSystemVersion,
    );
    final redirect = appLink
        ? Uri.https(SocialKeys.appLinkHost, _naverPath).toString()
        : '$_naverLegacyScheme://naverlogin';
    final url = Uri.https('nid.naver.com', '/oauth2.0/authorize', {
      'response_type': 'code',
      'client_id': SocialKeys.naverClientId,
      'redirect_uri': redirect,
      'state': state,
    });
    final String callback;
    try {
      callback = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: appLink ? 'https' : _naverLegacyScheme,
        options: const FlutterWebAuth2Options(
          httpsHost: SocialKeys.appLinkHost,
          httpsPath: _naverPath,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return null;
      rethrow;
    }
    final query = Uri.parse(callback).queryParameters;
    // access_denied or a user cancel comes back as `error`: not signed in, not a failure.
    if (query.containsKey('error')) return null;
    final code = query['code'];
    if (code == null || code.isEmpty || query['state'] != state) {
      throw const ApiException(502, 'naver_code_missing');
    }
    return '$code:$state';
  }
}

/// Random per attempt; Naver echoes it back and the server checks the echo (CSRF).
String _naverState() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

bool _googleReady = false;

class GoogleSocialSignIn extends SocialSignIn {
  const GoogleSocialSignIn();
  @override
  String get provider => SocialProviders.google;

  @override
  Future<String?> obtainToken(BuildContext context) async {
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize(
        // iOS needs its own OAuth client id; Android reads its client from google-services.json.
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? SocialKeys.googleIosClientId
            : null,
        serverClientId: SocialKeys.googleServerClientId,
      );
      _googleReady = true;
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return _requireToken(
        account.authentication.idToken,
        SocialProviders.google,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}

class AppleSocialSignIn extends SocialSignIn {
  const AppleSocialSignIn();
  @override
  String get provider => SocialProviders.apple;

  @override
  Future<String?> obtainToken(BuildContext context) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      return _requireToken(credential.identityToken, SocialProviders.apple);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }
}

/// A signed-in account without its token cannot be verified by the backend: report it, do not sign in.
String _requireToken(String? token, String provider) {
  if (token == null || token.isEmpty) {
    throw ApiException(502, '${provider}_token_missing');
  }
  return token;
}
