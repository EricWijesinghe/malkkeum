import 'package:core/auth_pay.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';

const _intent = CheckoutIntent(
  id: 'ck-1',
  amount: 52000,
  orderName: '화장실 청소',
  method: 'card',
  storeId: 'store-1',
  channelKey: 'ch-card',
);

void main() {
  test('web builds take the hosted redirect page, native builds the WebView', () {
    expect(paymentLauncherFor('https://api.example.com', isWeb: true), isA<PortOneRedirectLauncher>());
    expect(paymentLauncherFor('https://api.example.com', isWeb: false), isA<PortOneWebViewLauncher>());
  });

  test('the default follows kIsWeb', () {
    final launcher = paymentLauncherFor('https://api.example.com');
    expect(launcher, kIsWeb ? isA<PortOneRedirectLauncher>() : isA<PortOneWebViewLauncher>());
  });

  test('dev base keeps the simulated window, on web too', () {
    expect(paymentLauncherFor('http://127.0.0.1:8080', isWeb: true), isA<DevPaymentLauncher>());
    expect(paymentLauncherFor('http://localhost:8080', isWeb: false), isA<DevPaymentLauncher>());
  });

  test('redirect page carries the return path only when asked', () {
    final back = portOnePageUri('https://x', _intent, back: webPayReturnPath);
    expect(back.queryParameters['back'], '/app/#/pay-return');
    expect(back.queryParameters['checkout'], 'ck-1');
    expect(portOnePageUri('https://x', _intent).queryParameters.containsKey('back'), isFalse);
  });
}
