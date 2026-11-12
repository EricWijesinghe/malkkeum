import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'checkout.dart';
import 'dev_payment_sheet.dart';
import 'i18n.dart';
import 'desktop.dart';
import 'portone_browser.dart';
import 'portone_webview.dart';
import 'social_auth.dart';

/// What the PG window returned. A null PaymentOutcome means the customer closed the window.
sealed class PaymentOutcome {
  const PaymentOutcome();
}

/// Authorized; confirm with this payment id. Dev ids: `dev:<method>` (e.g. 'dev:kakaopay').
final class PaymentApproved extends PaymentOutcome {
  const PaymentApproved(this.paymentId);
  final String paymentId;
}

/// The PG declined or could not start. `code` is a server-style code (payment_failed, ...).
final class PaymentRejected extends PaymentOutcome {
  const PaymentRejected(this.code);
  final String code;
}

abstract class PaymentLauncher {
  const PaymentLauncher();

  /// Opens the PG window for [intent]. Returns null when the customer cancels.
  /// The context is needed to show the window; the launcher does not keep it.
  Future<PaymentOutcome?> pay({
    required BuildContext context,
    required CheckoutIntent intent,
  });
}

/// Simulated PG window for local development. Never charges anything.
class DevPaymentLauncher extends PaymentLauncher {
  const DevPaymentLauncher();

  @override
  Future<PaymentOutcome?> pay({
    required BuildContext context,
    required CheckoutIntent intent,
  }) async {
    final method = await showAppSheet<String>(
      context,
      title: context.t.apPgTitle,
      builder: (_) => DevPaymentSheet(intent: intent),
    );
    if (method == null) return null;
    // The method the customer picked in the window, so the server stores that one (not the checkout's first pick).
    return PaymentApproved('dev:$method');
  }
}

/// Dev base: simulated window. Web: the hosted PortOne page in this tab (no WebView on web).
/// Windows: the hosted page in the default browser (no WebView plugin there).
/// Mobile: the hosted page in a WebView. [isWeb] and [isWindows] default to the platform; tests pass them.
PaymentLauncher paymentLauncherFor(
  String apiBase, {
  bool? isWeb,
  bool? isWindows,
}) {
  if (isDevApiBase(apiBase)) return const DevPaymentLauncher();
  if (isWeb ?? kIsWeb) return PortOneRedirectLauncher(apiBase);
  if (isWindows ?? isWindowsApp()) return PortOneBrowserLauncher(apiBase);
  return PortOneWebViewLauncher(apiBase);
}

