import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Studio lists at 45,000; a 30% cap allows 13,500 P, the 8,000 P balance is the tighter limit.
Json _wallet({bool enabled = true}) => {
  'enabled': enabled,
  'balance': 8000,
  'max_use_bps': 3000,
  'entries': const <Json>[],
};

Future<FakeApi> _openCheckout(WidgetTester tester, {required Json wallet, List<Json>? methods, void Function(FakeApi)? routes}) async {
  setViewport(tester, tallPhoneSize);
  final fake = FakeApi();
  routes?.call(fake);
  fake
    ..reply('GET', '/me/points', wallet)
    ..reply('GET', '/payments/methods', [
      {'code': 'transfer', 'flow': 'checkout'},
    ])
    ..reply('GET', '/slots', [for (final h in const [8, 9, 13, 14]) slotJson(h)])
    // Refused on purpose: the test reads the request, the PG window is not part of it.
    ..reply('POST', '/checkouts', {
      'error': {'code': 'points_insufficient'},
    }, status: 409);
  stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 8)], methods: methods ?? const <Json>[]);
  final env = await TestEnv.create(fake: fake);
  await pumpCustomerApp(tester, env);
  await pumpUntilFound(tester, find.text(koT.service('studio')));
  await tester.tap(find.text(koT.service('studio')));
  await settle(tester);
  await tester.tap(find.text(koT.dfBookNow));
  await settle(tester);
  await tester.tap(find.text(koT.next).last); // date step
  await settle(tester);
  await tester.tap(find.text(koT.next).last); // prep tools step (studio needs tools)
  await settle(tester);
  expect(find.byType(CheckoutScreen), findsOneWidget);
  return fake;
}

Finder _pointsLine() => find.text('−${koT.walletPoints('8000')}');

void main() {
  testWidgets('applying points adds the points line, lowers the amount due and sends the points', (tester) async {
    final fake = await _openCheckout(tester, wallet: _wallet());

    // No method yet: "포인트 우선 사용" is offered but cannot be switched on.
    expect(find.text(koT.checkoutPointsNeedsWindow), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);

    // The pay button opens the method sheet while no method is chosen.
    await tester.tap(find.text(koT.needMethod).last);
    await settle(tester);
    await tester.tap(find.text(koT.payMethod('transfer')).last);
    await settle(tester);
    expect(find.text(koT.checkoutPointsAvail('8000', '8000')), findsOneWidget);
    expect(_pointsLine(), findsNothing, reason: 'points are opt-in');
    expect(find.text(koT.payAmount(formatWon(45000, 'ko'))), findsOneWidget);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
    expect(_pointsLine(), findsWidgets, reason: 'the points row and the breakdown line');
    final payLabel = koT.payAmount(formatWon(37000, 'ko'));
    expect(find.text(payLabel), findsOneWidget);
    expect(
      find.descendant(of: find.byType(RollingAmount), matching: find.text(formatWon(37000, 'ko'))),
      findsOneWidget,
      reason: 'the total is what the payment window will charge',
    );

    await tester.tap(find.text(payLabel));
    await settle(tester);
    final body = fake.lastCall('POST', '/checkouts')!.json;
    expect(body['points'], 8000);
    expect(body['kind'], 'booking');
    expect(body['method'], 'transfer');

    // Switching it back off restores the full amount.
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
    expect(_pointsLine(), findsNothing);
    expect(find.text(koT.payAmount(formatWon(45000, 'ko'))), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a saved-card payment retried after a lost reply sends the same Idempotency-Key', (tester) async {
    var attempts = 0;
    final fake = await _openCheckout(
      tester,
      wallet: _wallet(enabled: false),
      methods: [paymentMethodJson()],
      routes: (f) => f.onPost('/bookings', (_) {
        // The first reply is lost (the server may have charged); the retry gets an answer.
        if (attempts++ == 0) throw StateError('connection dropped');
        return const ApiReply(409, {'error': {'code': 'slot_full'}});
      }),
    );
    final pay = find.text(koT.payAmount(formatWon(45000, 'ko')));
    await tester.tap(pay);
    await settle(tester);
    await tester.tap(pay);
    await settle(tester);
    final keys = [for (final c in fake.callsTo('POST', '/bookings')) c.headers['idempotency-key']];
    expect(keys, hasLength(2));
    expect(keys.first, isNotNull);
    expect(keys.last, keys.first, reason: 'a retry of the same draft is the same action');
    await unmount(tester);
  });

  testWidgets('no points card when the programme is off', (tester) async {
    await _openCheckout(tester, wallet: _wallet(enabled: false));

    expect(find.byType(Checkbox), findsNothing);
    expect(find.text(koT.checkoutPointsUse), findsNothing);
    await unmount(tester);
  });
}
