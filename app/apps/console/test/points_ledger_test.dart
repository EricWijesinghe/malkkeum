import 'package:console/screens/points_ledger.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

const _ledgerPath = '/admin/growth/points/u-1';
const _adjustPath = '/admin/growth/points/adjust';

Json _entry(String kind, int amount, {String? reason}) => {
  'kind': kind,
  'amount': amount,
  'at': '2026-11-01T03:00:00Z',
  'expires_at': null,
  'booking_id': null,
  'reason': reason,
  'actor_id': reason == null ? null : 'st-1',
};

/// Ledger whose balance follows the adjustments the screen posts.
FakeApi _api() {
  var balance = 2500;
  return FakeApi()
    ..onGet(_ledgerPath, (_) => {
      'enabled': true,
      'balance': balance,
      'entries': [_entry('spend', -500), _entry('grant', 3000, reason: 'service recovery')],
    })
    ..onPost(_adjustPath, (c) {
      balance += c.json['amount'] as int;
      return {'ok': true};
    });
}

Future<void> _open(WidgetTester tester, FakeApi fake) async {
  setViewport(tester, tallPhoneSize);
  final env = await TestEnv.create(fake: fake, role: 'staff_admin');
  await pumpConsoleScreen(tester, env, const PointsLedgerPanel(userId: 'u-1'));
  await pumpUntilFound(tester, find.text(koT.walletPoints('2500')));
}

Future<void> _submit(WidgetTester tester, String amount, String reason) async {
  await tester.tap(find.byIcon(Icons.tune_rounded));
  await pumpUntilFound(tester, find.text(koT.pointsAdjustAmount));
  await tester.enterText(find.widgetWithText(TextField, koT.pointsAdjustAmount), amount);
  await tester.enterText(find.widgetWithText(TextField, koT.pointsAdjustReason), reason);
  await tester.tap(find.text(koT.save));
  await settle(tester);
}

void main() {
  testWidgets('ledger shows the balance and each entry with its staff reason', (tester) async {
    await _open(tester, _api());

    expect(find.text(koT.walletKindSpend), findsOneWidget);
    expect(find.text(koT.walletPoints('-500')), findsOneWidget);
    expect(find.text(koT.walletPoints('+3000')), findsOneWidget);
    expect(find.textContaining('service recovery'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('adjustment posts amount and reason once, then reloads the balance', (tester) async {
    final fake = _api();
    await _open(tester, fake);

    await _submit(tester, '-500', '  granted twice ');

    final call = fake.callsTo('POST', _adjustPath).single;
    expect(call.json, {'user_id': 'u-1', 'amount': -500, 'reason': 'granted twice'});
    expect(call.headers.keys.map((k) => k.toLowerCase()), contains('idempotency-key'));
    expect(find.text(koT.walletPoints('2000')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('adjustment without a reason or with zero points sends nothing', (tester) async {
    final fake = _api();
    await _open(tester, fake);

    await _submit(tester, '1000', '   ');
    expect(find.text(koT.pointsAdjustInvalid), findsOneWidget);
    await _submit(tester, '0', 'no change');

    expect(fake.callsTo('POST', _adjustPath), isEmpty);
    expect(find.text(koT.walletPoints('2500')), findsOneWidget);
    await unmount(tester);
  });
}
