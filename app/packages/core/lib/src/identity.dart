import 'dart:math';

import 'package:flutter/material.dart';

import 'api.dart';
import 'i18n.dart';
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

/// Integration point: PortOne identity verification (portone_flutter_v2 or the PortOne WebView).
/// Returns the identity_verification_id from the PortOne callback once the package is wired.
class PortOneIdentityVerifier extends IdentityVerifier {
  const PortOneIdentityVerifier();
  // TODO(portone): open PortOne identity verification with the store id and channel key
  // from the console; return the identityVerificationId from the redirect/callback.
  @override
  Future<String?> verify(BuildContext context) async => throw const ApiException(501, 'provider_not_configured');
}

/// POST /v1/me/identity. The server checks the verification with the PG before saving.
Future<void> submitIdentity(ApiClient api, String identityVerificationId) async {
  await api.post('/me/identity', {'identity_verification_id': identityVerificationId});
}

/// Dev base URL: confirm dialog. Anything else: the PortOne identity integration point.
IdentityVerifier identityVerifierFor(String apiBase) => isDevApiBase(apiBase) ? DevIdentityVerifier() : const PortOneIdentityVerifier();
