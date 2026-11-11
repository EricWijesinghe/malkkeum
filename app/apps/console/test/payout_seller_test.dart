import 'package:console/screens/people.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';
import 'support/payout_fixtures.dart';

const _sellerPath = '/admin/settlements/toss-sellers/pro-1';

Json _tossRequested() => {...payoutJson('po-5', 'requested'), 'provider': 'toss'};

Future<void> _pumpTossPayouts(WidgetTester tester, FakeApi fake) async {
  final env = await TestEnv.create(fake: fake, role: 'staff_admin');
  await pumpConsoleScreen(tester, env, const SettlementsScreen(initialPayouts: true));
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text(koT.poSellerAction));
  await pumpUntilFound(tester, find.text(koT.poSellerTitle));
}

Future<void> _fill(WidgetTester tester, String label, String value) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), value);
  await tester.pump();
}

void main() {
  testWidgets('seller action shows only for admins on Toss payouts that are requested or failed', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/settlements/payouts', [_tossRequested(), payoutJson('po-1', 'requested'), payoutJson('po-4', 'failed', failure: 'account_closed')]);
    await _pumpTossPayouts(tester, fake);
    await pumpUntilFound(tester, find.text(koT.poState_failed));

    // Only the Toss requested row offers it: manual and paid rows must not.
    expect(find.text(koT.poSellerAction), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('empty required fields block submit and send nothing', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/settlements/payouts', [_tossRequested()])
      ..reply('POST', _sellerPath, {'seller_status': 'approved', 'rev': 1});
    await _pumpTossPayouts(tester, fake);
    await pumpUntilFound(tester, find.text(koT.poSellerAction));
    await _openDialog(tester);

    await tester.tap(find.text(koT.poSellerSubmit));
    await settle(tester);

    expect(find.text(koT.required), findsWidgets);
    expect(fake.callsTo('POST', _sellerPath), isEmpty);
    await unmount(tester);
  });

  testWidgets('company registration posts digits only and shows the seller status', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/settlements/payouts', [_tossRequested()])
      ..reply('POST', _sellerPath, {'seller_status': 'approved', 'rev': 1});
    await _pumpTossPayouts(tester, fake);
    await pumpUntilFound(tester, find.text(koT.poSellerAction));
    await _openDialog(tester);

    await tester.tap(find.text(koT.poSellerCompany));
    await settle(tester);
    await _fill(tester, koT.poSellerName, 'Malkkeum Clean');
    await _fill(tester, koT.poSellerRepresentative, 'Kim Minsoo');
    await _fill(tester, koT.poSellerRegNo, '123-45-67890');
    await _fill(tester, koT.poSellerEmail, 'pro@example.com');
    await _fill(tester, koT.poSellerPhone, '010-1234-5678');
    await tester.tap(find.text(koT.poSellerSubmit));
    await pumpUntilFound(tester, find.text(koT.poSellerDone('approved')));

    final sent = fake.callsTo('POST', _sellerPath).single.body as Json;
    expect(sent['business_type'], 'company');
    expect(sent['registration_no'], '1234567890');
    expect(sent['phone'], '01012345678');
    expect(sent['representative'], 'Kim Minsoo');
    await unmount(tester);
  });

  testWidgets('a declined seller shows the localized reason and keeps the dialog open', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/settlements/payouts', [_tossRequested()])
      ..reply('POST', _sellerPath, {'error': {'code': 'seller_declined'}}, status: 409);
    await _pumpTossPayouts(tester, fake);
    await pumpUntilFound(tester, find.text(koT.poSellerAction));
    await _openDialog(tester);

    await _fill(tester, koT.poSellerName, 'Kim Minsoo');
    await _fill(tester, koT.poSellerEmail, 'pro@example.com');
    await _fill(tester, koT.poSellerPhone, '01012345678');
    await tester.tap(find.text(koT.poSellerSubmit));
    await pumpUntilFound(tester, find.text(koT.err_seller_declined));

    expect(find.text(koT.poSellerTitle), findsOneWidget);
    expect(find.textContaining('ApiException'), findsNothing);
    await unmount(tester);
  });
}
