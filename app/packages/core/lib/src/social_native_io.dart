import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api.dart';
import 'social_auth.dart';

/// Must match the URL scheme in ios/Runner/Info.plist (Naver's iOS callback).
const _naverUrlScheme = 'malkkeumnaver';

/// Native SDK for each provider. Returns what the backend verifies (backend/crates/api/src/providers/social.rs):
/// Kakao and Naver: access token. Google: ID token. Apple: identity token.
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

bool _naverReady = false;

class NaverSocialSignIn extends SocialSignIn {
  const NaverSocialSignIn();
  @override
  String get provider => SocialProviders.naver;

  @override
  Future<String?> obtainToken(BuildContext context) async {
    if (!_naverReady) {
      await NaverLoginSDK.initialize(
        urlScheme: _naverUrlScheme,
        clientId: SocialKeys.naverClientId,
        clientSecret: SocialKeys.naverClientSecret,
        clientName: SocialKeys.naverClientName,
      );
      _naverReady = true;
    }
    // false = cancelled or failed; the SDK's failure reason only reaches callbacks, so both read as "not signed in".
    final ok = await NaverLoginSDK.login();
    if (!ok) return null;
    return NaverLoginSDK.getAccessToken();
  }
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
        clientId: defaultTargetPlatform == TargetPlatform.iOS ? SocialKeys.googleIosClientId : null,
        serverClientId: SocialKeys.googleServerClientId,
      );
      _googleReady = true;
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return _requireToken(account.authentication.idToken, SocialProviders.google);
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
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
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
  if (token == null || token.isEmpty) throw ApiException(502, '${provider}_token_missing');
  return token;
}
