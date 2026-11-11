import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'api.dart';
import 'desktop.dart';
import 'i18n.dart';
import 'models.dart';
import 'portone_webview.dart';
import 'social_auth.dart';

/// Runs the PASS 본인인증 flow and returns an identity_verification_id, or null on cancel.
abstract class IdentityVerifier {
  const IdentityVerifier();
  Future<String?> verify(BuildContext context);
}

/// Dev stand-in: a confirm dialog that issues a dev-prefixed id without any carrier check.
class DevIdentityVerifier extends IdentityVerifier {
  DevIdentityVerifier({Random? random}) : _random = random ?? Random.secure();
  final Random _random;

  @override
  Future<String?> verify(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t.apIdentityDevTitle),
        content: Text(ctx.t.apIdentityDevBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(ctx.t.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(ctx.t.apIdentityDevPass)),
        ],
      ),
    );
    if (ok != true) return null;
    return 'dev:${_random.nextInt(1 << 30).toRadixString(36)}';
  }
}

/// PortOne PASS in the hosted page (WebView). The API issues a single-use verification id first; the page
/// returns the same id, and the caller submits it so the server checks it with PortOne.
class PortOneIdentityVerifier extends IdentityVerifier {
  const PortOneIdentityVerifier(this.api);
  final ApiClient api;

  @override
  Future<String?> verify(BuildContext context) async {
    final s = await api.post('/me/identity/session') as Json;
    final uri = Uri.parse('${api.baseUrl}/pay/identity.html').replace(
      queryParameters: {
        'store': s['store_id'] as String,
        'channel': s['channel_key'] as String,
        'id': s['identity_verification_id'] as String,
      },
    );
    if (!context.mounted) return null;
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HostedPage<String?>(
          uri: uri,
          donePath: identityDonePath,
          title: context.t.apIdentityTitle,
          onDone: identityIdFromRedirect,
        ),
      ),
    );
  }
}

/// Path the hosted identity page redirects to; the WebView intercepts it.
const identityDonePath = '/pay/identity-done.html';

/// Reads `identityVerificationId` from the redirect. Missing or empty (cancel, error) reads as null.
String? identityIdFromRedirect(Uri uri) {
  final id = uri.queryParameters['identityVerificationId'];
  return id == null || id.isEmpty ? null : id;
}

/// Whether PASS can be offered here: the server has the identity channel, and the WebView exists
/// (web and Windows builds have none). A failed read hides it.
Future<bool> identityAvailable(ApiClient api) async {
  if (kIsWeb || isWindowsApp()) return false;
  try {
    final v = await api.get('/me/identity/setup') as Json;
    return v['enabled'] as bool? ?? false;
  } on Object {
    return false;
  }
}

/// POST /v1/me/identity. The server checks the verification with the PG before saving.
Future<void> submitIdentity(ApiClient api, String identityVerificationId) async {
  await api.post('/me/identity', {'identity_verification_id': identityVerificationId});
}

/// Dev base URL: confirm dialog. Anything else: the PortOne identity integration point.
IdentityVerifier identityVerifierFor(ApiClient api) => isDevApiBase(api.baseUrl) ? DevIdentityVerifier() : PortOneIdentityVerifier(api);
