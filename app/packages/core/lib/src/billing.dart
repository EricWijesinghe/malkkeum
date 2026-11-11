import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'api.dart';
import 'desktop.dart';
import 'portone_webview.dart';

/// Server's answer for saving a card: PortOne store and per-method channel keys. Disabled until PortOne is configured.
class BillingSetup {
  const BillingSetup({
    required this.enabled,
    this.storeId = '',
    this.channels = const {},
    this.issueId = '',
    this.customerId = '',
  });
  final bool enabled;
  final String storeId;
  final Map<String, String> channels;
  final String issueId;

  /// PortOne `customer.customerId`: the server checks the issued key belongs to this customer.
  final String customerId;

  static const off = BillingSetup(enabled: false);

  factory BillingSetup.fromJson(Map<String, dynamic> j) {
    if (j['enabled'] != true) return off;
    return BillingSetup(
      enabled: true,
      storeId: j['store_id'] as String? ?? '',
      channels: {
        for (final e in (j['channels'] as Map? ?? {}).entries)
          e.key as String: e.value as String,
      },
      issueId: j['issue_id'] as String? ?? '',
      customerId: j['customer_id'] as String? ?? '',
    );
  }

  /// Whether [provider] can be saved for one-tap payment right now.
  /// Card registration runs in a WebView, which the web and Windows builds lack, so saved cards are phone-only.
  bool supports(String provider) =>
      !kIsWeb && !isWindowsApp() && enabled && channels.containsKey(provider);
}

/// A failed read means the option stays hidden.
Future<BillingSetup> fetchBillingSetup(ApiClient api) async {
  try {
    return BillingSetup.fromJson(
      await api.get('/me/payment-methods/setup') as Map<String, dynamic>,
    );
  } on Object {
    return BillingSetup.off;
  }
}

/// Opens PortOne's card registration (hosted page in a WebView) and returns the issued billing key.
/// Null when the customer backs out or registration fails; the server verifies the key on save.
Future<String?> issueBillingKey({
  required BuildContext context,
  required String apiBase,
  required BillingSetup setup,
  required String provider,
  required String pageTitle,
}) {
  final uri = Uri.parse('$apiBase/pay/billing.html').replace(
    queryParameters: {
      'store': setup.storeId,
      'channel': setup.channels[provider] ?? '',
      'issue': setup.issueId,
      'customer': setup.customerId,
      'method': provider,
    },
  );
  return Navigator.of(context).push<String?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => HostedPage<String?>(
        uri: uri,
        donePath: billingDonePath,
        title: pageTitle,
        onDone: billingKeyFromRedirect,
      ),
    ),
  );
}

/// Path the hosted billing page redirects to; the WebView intercepts it.
const billingDonePath = '/pay/billing-done.html';

/// Reads `billingKey` from the redirect. Missing or empty (cancel, error) reads as null.
String? billingKeyFromRedirect(Uri uri) {
  final key = uri.queryParameters['billingKey'];
  return key == null || key.isEmpty ? null : key;
}
