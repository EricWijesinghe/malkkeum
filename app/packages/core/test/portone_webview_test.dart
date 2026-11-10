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
    'android intent links become the app scheme plus a Play Store fallback',
    () {
      final t = parseAndroidIntent(
        'intent://pay?srCode=123#Intent;scheme=kakaotalk;package=com.kakao.talk;end',
      );
      expect(t.app.toString(), 'kakaotalk://pay?srCode=123');
      expect(t.store.toString(), 'market://details?id=com.kakao.talk');
      expect(parseAndroidIntent('https://example.com').app, isNull);
    },
  );
}
