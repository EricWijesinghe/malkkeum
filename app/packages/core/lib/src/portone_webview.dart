import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'checkout.dart';
import 'i18n.dart';
import 'payment_launcher.dart';

/// PortOne `appScheme` for the in-app WebView: ISP and app-card apps open it to bring the
/// customer back after authenticating. Registered in the customer iOS Info.plist (check-native.py).
const payAppScheme = 'malkkeumpay://';

/// URL of our hosted PortOne page for [intent] (website/pay/index.html, same domain as the API).
/// `paymentId` is the checkout id there: the webhook and the recovery pass depend on it.
/// [app] is the app's return scheme; only the WebView passes it.
Uri portOnePageUri(
  String apiBase,
  CheckoutIntent intent, {
  String? phone,
  String? back,
  String? app,
}) => Uri.parse('$apiBase/pay/').replace(
  queryParameters: {
    'checkout': intent.id,
    'store': intent.storeId,
    'channel': intent.channelKey,
    'amount': '${intent.amount}',
    'method': intent.method,
    'name': intent.orderName,
    'phone': ?phone,
    'back': ?back,
    'app': ?app,
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
/// Approved only means "ask the server": the payment id is always the checkout id (never the
/// redirect's), and the server's confirm asks PortOne for the real status and amount.
PaymentOutcome? outcomeFromRedirect(Uri uri, String checkoutId) {
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) return PaymentApproved(checkoutId);
  if (_cancelCodes.contains(code)) return null;
  return const PaymentRejected('payment_failed');
}

final _androidPackage = RegExp(
  r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
);

final _scheme = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:');

/// What to open for a non-web navigation in the payment WebView, in order; the first one that
/// opens wins. App links (`ispmobile://TID=…`, `kakaotalk://…`) are tried as they are: kept as
/// text, because Uri would lowercase the host and some card apps read it. Android `intent:` links
/// (`intent://pay#Intent;scheme=x;package=y;S.browser_fallback_url=z;end`, or Toss's
/// `intent:x://pay#Intent;…;end`) become the app link, then the https fallback page, then the
/// app's Play Store page. Empty when nothing can be opened.
List<String> appLinkTargets(String url) {
  final hash = url.indexOf('#Intent;');
  if (!url.startsWith('intent:') || hash < 0) {
    return _scheme.hasMatch(url) ? [url] : const [];
  }
  final params = <String, String>{
    for (final part in url.substring(hash + 8).split(';'))
      if (part.contains('='))
        part.substring(0, part.indexOf('=')): part.substring(
          part.indexOf('=') + 1,
        ),
  };
  final body = url.substring('intent:'.length, hash);
  final scheme = params['scheme'];
  final app = scheme != null ? '$scheme:$body' : body;
  final fallback = _fallbackOf(params['S.browser_fallback_url']);
  final pkg = params['package'];
  return [
    if (_scheme.hasMatch(app) && !app.startsWith('intent:')) app,
    ?fallback,
    if (pkg != null && _androidPackage.hasMatch(pkg))
      'market://details?id=$pkg',
  ];
}

/// The intent's percent-encoded `S.browser_fallback_url`, kept only when it is https or market.
String? _fallbackOf(String? raw) {
  if (raw == null) return null;
  try {
    final url = Uri.decodeComponent(raw);
    return url.startsWith('https://') || url.startsWith('market://')
        ? url
        : null;
  } on ArgumentError {
    return null; // malformed percent-encoding
  }
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
    final uri = portOnePageUri(
      apiBase,
      intent,
      phone: phone,
      back: webPayReturnPath,
    );
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
        builder: (_) => HostedPage<PaymentOutcome?>(
          uri: portOnePageUri(apiBase, intent, phone: phone, app: payAppScheme),
          donePath: '/pay/done.html',
          title: context.t.apPgTitle,
          onDone: (done) => outcomeFromRedirect(done, intent.id),
        ),
      ),
    );
  }
}

/// Our hosted PortOne page in a WebView. The page ends by redirecting to [donePath]; [onDone]
/// turns that redirect into the pop result. Card and wallet apps are handed to the OS.
class HostedPage<T> extends StatefulWidget {
  const HostedPage({
    required this.uri,
    required this.donePath,
    required this.title,
    required this.onDone,
    super.key,
  });
  final Uri uri;
  final String donePath;
  final String title;
  final T? Function(Uri done) onDone;

  @override
  State<HostedPage<T>> createState() => _HostedPageState<T>();
}

class _HostedPageState<T> extends State<HostedPage<T>> {
  late final WebViewController _web;
  bool _finished = false;
  bool _failed = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _route,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onWebResourceError: (e) {
            // A failed image or script inside the page is the page's problem; a failed page is ours.
            if (mounted && (e.isForMainFrame ?? true)) {
              setState(() => _failed = true);
            }
          },
        ),
      )
      ..loadRequest(widget.uri);
  }

  void _finish(T? outcome) {
    if (_finished) return;
    _finished = true;
    Navigator.of(context).pop<T>(outcome);
  }

  Future<void> _retry() async {
    setState(() {
      _failed = false;
      _progress = 0;
    });
    // A first load that never committed has nothing to reload.
    final url = await _web.currentUrl();
    if (url == null || url.isEmpty || url == 'about:blank') {
      await _web.loadRequest(widget.uri);
    } else {
      await _web.reload();
    }
  }

  /// System back walks the page's own history (3DS and card-company steps) and cancels only
  /// from the first page.
  Future<void> _back() async {
    if (_finished) return;
    if (!_failed && await _web.canGoBack()) {
      await _web.goBack();
    } else if (mounted) {
      _finish(null);
    }
  }

  /// https only. Cleartext http is allowed only back to our own page's origin when that page is
  /// itself http (a local dev API).
  bool _webAllowed(Uri uri) =>
      uri.scheme == 'https' ||
      uri.scheme == 'about' ||
      (uri.scheme == 'http' &&
          widget.uri.scheme == 'http' &&
          uri.host == widget.uri.host &&
          uri.port == widget.uri.port);

  Future<NavigationDecision> _route(NavigationRequest req) async {
    // Some intent: links are not valid URIs; appLinkTargets reads them as text.
    final uri = Uri.tryParse(req.url);
    if (uri != null) {
      if (uri.path.endsWith(widget.donePath) && uri.host == widget.uri.host) {
        _finish(widget.onDone(uri));
        return NavigationDecision.prevent;
      }
      if (_webAllowed(uri)) return NavigationDecision.navigate;
      if (uri.scheme == 'http') return NavigationDecision.prevent;
    }
    // Card / wallet apps (ISP, KakaoTalk, Toss, bank apps): hand them to the OS. The page keeps
    // waiting here; the app returns by finishing (Android) or through payAppScheme (iOS).
    for (final target in appLinkTargets(req.url)) {
      if (target.startsWith('https://')) {
        await _web.loadRequest(Uri.parse(target));
        break;
      }
      if (await _open(target)) break;
    }
    return NavigationDecision.prevent;
  }

  /// False when no installed app takes [target] (url_launcher reports that, or throws on some).
  Future<bool> _open(String target) async {
    try {
      return await launchUrlString(
        target,
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<T>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => _finish(null),
        ),
        bottom: _progress < 100 && !_failed
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _web),
            if (_failed) Positioned.fill(child: _offline(context)),
          ],
        ),
      ),
    ),
  );

  Widget _offline(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(context.t.errorNetwork, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _retry, child: Text(context.t.retry)),
          ],
        ),
      ),
    ),
  );
}
