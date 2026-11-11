import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'checkout.dart';
import 'i18n.dart';
import 'payment_launcher.dart';
import 'portone_webview.dart';

/// Windows: no WebView plugin, so the hosted PortOne page opens in the default browser.
/// The customer comes back and taps "done"; the server then verifies the payment with PortOne
/// (confirm), so a false tap is rejected there.
class PortOneBrowserLauncher extends PaymentLauncher {
  const PortOneBrowserLauncher(this.apiBase, {this.phone});
  final String apiBase;
  final String? phone;

  @override
  Future<PaymentOutcome?> pay({
    required BuildContext context,
    required CheckoutIntent intent,
  }) async {
    if (intent.storeId.isEmpty || intent.channelKey.isEmpty) {
      return const PaymentRejected('provider_not_configured');
    }
    final uri = portOnePageUri(apiBase, intent, phone: phone);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) return const PaymentRejected('payment_failed');
    if (!context.mounted) return null;
    final done = await showAppSheet<bool>(
      context,
      title: context.t.apPgTitle,
      builder: (_) => const _BrowserReturnSheet(),
    );
    if (done != true) return null;
    // The hosted page reports the checkout id as the payment id (see outcomeFromRedirect).
    return PaymentApproved(intent.id);
  }
}

class _BrowserReturnSheet extends StatelessWidget {
  const _BrowserReturnSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.apPgBrowserNote,
            style: context.text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.md),
          PrimaryButton(
            label: t.apPgBrowserDone,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: Space.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.apPgCancel),
          ),
        ],
      ),
    );
  }
}
