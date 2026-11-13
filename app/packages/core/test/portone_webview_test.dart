import 'package:core/auth_pay.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
