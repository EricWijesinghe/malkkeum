import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'checkout.dart';
import 'i18n.dart';
import 'payment_launcher.dart';

/// URL of our hosted PortOne page for [intent] (website/pay/index.html, same domain as the API).
/// `paymentId` is the checkout id there: the webhook and the recovery pass depend on it.
Uri portOnePageUri(String apiBase, CheckoutIntent intent, {String? phone, String? back}) =>
    Uri.parse('$apiBase/pay/').replace(
      queryParameters: {
        'checkout': intent.id,
        'store': intent.storeId,
        'channel': intent.channelKey,
        'amount': '${intent.amount}',
        'method': intent.method,
        'name': intent.orderName,
        'phone': ?phone,
        'back': ?back,
      },
    );

/// Where the web app resumes after the hosted page (same origin, hash route, see customer web_return).
const webPayReturnPath = '/app/#/pay-return';

/// Result codes PortOne puts on the redirect when the customer backs out.
const _cancelCodes = {
  'PAY_PROCESS_CANCELED',
  'USER_CANCEL',
  'FAILURE_TYPE_USER_CANCEL',
};

/// Reads the redirect to /pay/done.html. Null when the customer cancelled.
PaymentOutcome? outcomeFromRedirect(Uri uri, String checkoutId) {
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) {
    return PaymentApproved(uri.queryParameters['paymentId'] ?? checkoutId);
  }
  if (_cancelCodes.contains(code)) return null;
  return const PaymentRejected('payment_failed');
}

/// Android card and wallet apps arrive as `intent://…#Intent;scheme=x;package=y;end`.
/// Returns the app link and the Play Store fallback.
({Uri? app, Uri? store}) parseAndroidIntent(String url) {
  final hash = url.indexOf('#Intent;');
  if (!url.startsWith('intent://') || hash < 0) return (app: null, store: null);
  final params = <String, String>{
    for (final part in url.substring(hash + 8).split(';'))
      if (part.contains('='))
        part.substring(0, part.indexOf('=')): part.substring(
          part.indexOf('=') + 1,
        ),
  };
  final scheme = params['scheme'];
  final pkg = params['package'];
  final app = scheme == null
      ? null
      : Uri.tryParse('$scheme://${url.substring(9, hash)}');
  final store = pkg == null ? null : Uri.parse('market://details?id=$pkg');
  return (app: app, store: store);
}

/// Web: the hosted PortOne page replaces this tab. The page sends the customer back to
/// [webPayReturnPath] when done, so the app confirms the payment after the reload.
class PortOneRedirectLauncher extends PaymentLauncher {
  const PortOneRedirectLauncher(this.apiBase, {this.phone});
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
    final uri = portOnePageUri(apiBase, intent, phone: phone, back: webPayReturnPath);
    await launchUrl(uri, webOnlyWindowName: '_self');
    // The page unloads now; a null outcome only matters if the navigation was blocked.
    return null;
  }
}

/// Real PG window: our hosted PortOne page in a WebView.
class PortOneWebViewLauncher extends PaymentLauncher {
  const PortOneWebViewLauncher(this.apiBase, {this.phone});
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
    return Navigator.of(context).push<PaymentOutcome?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PayPage(
          uri: portOnePageUri(apiBase, intent, phone: phone),
          checkoutId: intent.id,
        ),
      ),
    );
  }
}

class _PayPage extends StatefulWidget {
  const _PayPage({required this.uri, required this.checkoutId});
  final Uri uri;
  final String checkoutId;

  @override
  State<_PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<_PayPage> {
  late final WebViewController _web;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: _route))
      ..loadRequest(widget.uri);
  }

  void _finish(PaymentOutcome? outcome) {
    if (_finished) return;
    _finished = true;
    Navigator.of(context).pop(outcome);
  }

  Future<NavigationDecision> _route(NavigationRequest req) async {
    final uri = Uri.tryParse(req.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.path.endsWith('/pay/done.html') && uri.host == widget.uri.host) {
      _finish(outcomeFromRedirect(uri, widget.checkoutId));
      return NavigationDecision.prevent;
    }
    if (uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'about') {
      return NavigationDecision.navigate;
    }
    // Card / wallet apps (ISP, KakaoTalk, Toss, bank apps): hand them to the OS.
    if (uri.scheme == 'intent') {
      final target = parseAndroidIntent(req.url);
      final opened =
          target.app != null &&
          await launchUrl(target.app!, mode: LaunchMode.externalApplication);
      if (!opened && target.store != null) {
        await launchUrl(target.store!, mode: LaunchMode.externalApplication);
      }
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return NavigationDecision.prevent;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.apPgTitle),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: () => _finish(null),
      ),
    ),
    body: SafeArea(child: WebViewWidget(controller: _web)),
  );
}
