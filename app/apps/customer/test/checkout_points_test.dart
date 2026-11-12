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

Future<FakeApi> _openCheckout(WidgetTester tester, {required Json wallet, List<Json>? methods}) async {
  setViewport(tester, tallPhoneSize);
  final fake = FakeApi()
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
  await pumpUntilFound(tester, find.text(koT.serviceShort('studio')));
  await tester.tap(find.text(koT.serviceShort('studio')));
  await settle(tester);
  await tester.tap(find.text(koT.chooseDate));
  await settle(tester);
  await tester.tap(find.text(koT.goToPayment));
  await settle(tester);
  expect(find.byType(CheckoutScreen), findsOneWidget);
  return fake;
}

Finder _pointsLine() => find.text('−${koT.walletPoints('8000')}');

void main() {
  testWidgets('applying points adds the points line, lowers the amount due and sends the points', (tester) async {
    final fake = await _openCheckout(tester, wallet: _wallet());

    // No method yet: the card is offered but cannot be switched on.
    expect(find.text(koT.checkoutPointsNeedsWindow), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged, isNull);

    await tester.ensureVisible(find.text(koT.payMethod('transfer')));
    await tester.tap(find.text(koT.payMethod('transfer')));
    await settle(tester);
    expect(find.text(koT.checkoutPointsAvail('8000', '8000')), findsOneWidget);
    expect(_pointsLine(), findsNothing, reason: 'points are opt-in');
    expect(find.text(koT.payAmount(formatWon(45000, 'ko'))), findsOneWidget);

    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await settle(tester);
    expect(_pointsLine(), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
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
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await settle(tester);
    expect(_pointsLine(), findsNothing);
    expect(find.text(koT.payAmount(formatWon(45000, 'ko'))), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('no points card when the programme is off', (tester) async {
    await _openCheckout(tester, wallet: _wallet(enabled: false));

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text(koT.checkoutPointsUse), findsNothing);
    await unmount(tester);
  });
}
