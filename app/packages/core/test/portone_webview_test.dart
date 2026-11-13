import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:core/src/portone_webview.dart' show HostedPage;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Records what the payment page asks of the WebView, and lets a test drive its callbacks.
class _FakeWeb extends WebViewPlatform {
  final controller = <_FakeController>[];
  final delegate = <_FakeDelegate>[];

  @override
  PlatformWebViewController createPlatformWebViewController(PlatformWebViewControllerCreationParams params) =>
      (controller..add(_FakeController(params))).last;

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(PlatformNavigationDelegateCreationParams params) =>
      (delegate..add(_FakeDelegate(params))).last;

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) => _FakeWidget(params);
}

class _FakeController extends PlatformWebViewController {
  _FakeController(super.params) : super.implementation();
  final loads = <Uri>[];
  var history = 0;
  var backs = 0;
  var reloads = 0;
  String? url;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async => loads.add(params.uri);
  @override
  Future<String?> currentUrl() async => url;
  @override
  Future<bool> canGoBack() async => history > 0;
  @override
  Future<void> goBack() async {
    history--;
    backs++;
  }

  @override
  Future<void> reload() async => reloads++;
}

class _FakeDelegate extends PlatformNavigationDelegate {
  _FakeDelegate(super.params) : super.implementation();
  NavigationRequestCallback? onRequest;
  WebResourceErrorCallback? onError;
  ProgressCallback? onProgress;

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async => onRequest = onNavigationRequest;
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async => onError = onWebResourceError;
  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async => this.onProgress = onProgress;
}

class _FakeWidget extends PlatformWebViewWidget {
  _FakeWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Opens the hosted page over a home route; the future completes with its pop result.
Future<Future<String?>> _open(WidgetTester tester, Uri page) async {
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: nav,
    locale: const Locale('ko'),
    localizationsDelegates: T.localizationsDelegates,
    supportedLocales: T.supportedLocales,
    home: const SizedBox(),
  ));
  final result = nav.currentState!.push<String?>(MaterialPageRoute(
    builder: (_) => HostedPage<String>(uri: page, donePath: '/pay/done.html', title: 'PG', onDone: (u) => u.queryParameters['code'] ?? 'ok'),
  ));
  await _settle(tester);
  return result;
}

/// The loading bar is indeterminate until the page reports progress, so pumpAndSettle never settles:
/// pump past the route transition instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

NavigationRequest _nav(String url) => NavigationRequest(url: url, isMainFrame: true);

final koT = lookupT(const Locale('ko'));

const _intent = CheckoutIntent(
  id: 'ck-1',
  amount: 52000,
  orderName: '화장실 청소',
  method: 'kakaopay',
  storeId: 'store-1',
  channelKey: 'ch-kakao',
);

void main() {
  test(
    'hosted page carries the checkout id as paymentId and every PG field',
    () {
      final u = portOnePageUri(
        'https://malkkeum.co.kr',
        _intent,
        phone: '01012345678',
      );
      expect(u.path, '/pay/');
      expect(u.queryParameters, {
        'checkout': 'ck-1',
        'store': 'store-1',
        'channel': 'ch-kakao',
        'amount': '52000',
        'method': 'kakaopay',
        'name': '화장실 청소',
        'phone': '01012345678',
      });
      expect(
        portOnePageUri(
          'https://x',
          _intent,
        ).queryParameters.containsKey('phone'),
        isFalse,
      );
    },
  );

  test('redirect: success, cancel and failure', () {
    final ok = outcomeFromRedirect(
      Uri.parse('https://x/pay/done.html?paymentId=ck-1'),
      'ck-1',
    );
    expect(
      ok,
      isA<PaymentApproved>().having((p) => p.paymentId, 'paymentId', 'ck-1'),
    );
    expect(
      outcomeFromRedirect(
        Uri.parse(
          'https://x/pay/done.html?paymentId=ck-1&code=PAY_PROCESS_CANCELED',
        ),
        'ck-1',
      ),
      isNull,
    );
    final failed = outcomeFromRedirect(
      Uri.parse(
        'https://x/pay/done.html?paymentId=ck-1&code=FAILURE_TYPE_PG&message=limit',
      ),
      'ck-1',
    );
    expect(
      failed,
      isA<PaymentRejected>().having((p) => p.code, 'code', 'payment_failed'),
    );
  });

  test(
    'the WebView page carries the app return scheme; the web page does not',
    () {
      expect(payAppScheme, 'malkkeumpay://');
      expect(
        portOnePageUri(
          'https://x',
          _intent,
          app: payAppScheme,
        ).queryParameters['app'],
        'malkkeumpay://',
      );
      expect(
        portOnePageUri('https://x', _intent).queryParameters.containsKey('app'),
        isFalse,
      );
    },
  );

  test('approval always names the checkout, never the redirect paymentId', () {
    final ok = outcomeFromRedirect(
      Uri.parse('https://x/pay/done.html?paymentId=someone-elses'),
      'ck-1',
    );
    expect(
      ok,
      isA<PaymentApproved>().having((p) => p.paymentId, 'paymentId', 'ck-1'),
    );
  });

  group('appLinkTargets', () {
    List<String> targets(String url) => appLinkTargets(url);

    test('intent:// becomes the app scheme, then the Play Store page', () {
      expect(
        targets(
          'intent://pay?srCode=123#Intent;scheme=kakaotalk;package=com.kakao.talk;end',
        ),
        ['kakaotalk://pay?srCode=123', 'market://details?id=com.kakao.talk'],
      );
    });

    test('Toss style intent:<app link> keeps the app link', () {
      expect(
        targets(
          'intent:supertoss://pay?x=1#Intent;package=viva.republica.toss;end',
        ),
        ['supertoss://pay?x=1', 'market://details?id=viva.republica.toss'],
      );
    });

    test('browser_fallback_url comes before the store and must be https', () {
      expect(
        targets(
          'intent://p#Intent;scheme=ispmobile;package=kvp.jjy.MispAndroid320;'
          'S.browser_fallback_url=https%3A%2F%2Fpg.example%2Fisp%3Fa%3D1;end',
        ),
        [
          'ispmobile://p',
          'https://pg.example/isp?a=1',
          'market://details?id=kvp.jjy.MispAndroid320',
        ],
      );
      expect(
        targets(
          'intent://p#Intent;scheme=x;S.browser_fallback_url=javascript%3Aalert(1);end',
        ),
        ['x://p'],
      );
      expect(
        targets(
          'intent://p#Intent;scheme=x;S.browser_fallback_url=%E0%A4%A;end',
        ),
        ['x://p'],
      );
    });

    test(
      'a package that is not a package name is not put in the store link',
      () {
        expect(targets('intent://p#Intent;package=a&id=evil;end'), isEmpty);
      },
    );

    test('plain app schemes pass through; junk opens nothing', () {
      expect(targets('ispmobile://TID=1'), ['ispmobile://TID=1']);
      expect(targets('kftc-bankpay://eftpay?x=1'), [
        'kftc-bankpay://eftpay?x=1',
      ]);
      expect(targets('not a url'), isEmpty);
      expect(targets('intent:#Intent;end'), isEmpty);
    });
  });

  group('hosted payment page', () {
    late _FakeWeb web;
    setUp(() => WebViewPlatform.instance = web = _FakeWeb());
    final page = Uri.parse('https://pay.example.com/pay/?checkout=ck-1');

    testWidgets('offline shows error and retry; retry loads the page again', (tester) async {
      await _open(tester, page);
      final ctl = web.controller.single;
      expect(ctl.loads, [page]);
      web.delegate.single.onError!(const WebResourceError(errorCode: -2, description: 'offline', isForMainFrame: true));
      await tester.pump();
      expect(find.text(koT.errorNetwork), findsOneWidget);

      await tester.tap(find.text(koT.retry));
      await tester.pump();
      expect(find.text(koT.errorNetwork), findsNothing);
      expect(ctl.loads, [page, page], reason: 'the first load never committed, so it loads again');
    });

    testWidgets('a failed sub-resource does not cover the page', (tester) async {
      await _open(tester, page);
      web.delegate.single.onError!(const WebResourceError(errorCode: -1, description: 'img', isForMainFrame: false));
      await tester.pump();
      expect(find.text(koT.errorNetwork), findsNothing);
    });

    testWidgets('back walks the page history before it cancels', (tester) async {
      final result = await _open(tester, page);
      final ctl = web.controller.single..history = 1;
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(ctl.backs, 1);
      expect(find.byType(HostedPage<String>), findsOneWidget, reason: 'a 3DS step went back, the payment is still open');

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.byType(HostedPage<String>), findsNothing);
      expect(await result, isNull, reason: 'back on the first page cancels');
    });

    testWidgets('cleartext http is refused; https and the done redirect are handled', (tester) async {
      final result = await _open(tester, page);
      final route = web.delegate.single.onRequest!;
      expect(await route(_nav('http://evil.example.com/steal')), NavigationDecision.prevent);
      expect(await route(_nav('http://pay.example.com/pay/x')), NavigationDecision.prevent, reason: 'our https page never downgrades');
      expect(await route(_nav('https://pg.example.com/3ds')), NavigationDecision.navigate);
      expect(await route(_nav('https://pay.example.com/pay/done.html?code=X')), NavigationDecision.prevent);
      await _settle(tester);
      expect(await result, 'X');
    });

    testWidgets('a local http dev page may navigate within its own origin only', (tester) async {
      await _open(tester, Uri.parse('http://10.0.2.2:8080/pay/'));
      final route = web.delegate.single.onRequest!;
      expect(await route(_nav('http://10.0.2.2:8080/pay/step')), NavigationDecision.navigate);
      expect(await route(_nav('http://10.0.2.2:9999/pay/step')), NavigationDecision.prevent);
    });
  });
}
