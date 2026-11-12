import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:customer/screens/more.dart';
import 'package:customer/screens/payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Tall enough that the lazily built More list has every row on screen.
const _tall = Size(390, 2400);

FakeApi _api() {
  final fake = FakeApi()
    // First match wins: these override the stock profile.
    ..reply('GET', '/me', {'name': '지민', 'phone': '01012345678', 'email': 'jimin@example.com', 'logins': ['kakao']})
    ..reply('GET', '/me/points', {'balance': 1200, 'entries': const <Json>[]})
    ..reply('GET', '/payments/methods', [
      {'code': 'card', 'flow': 'billing'},
      {'code': 'kakaopay', 'flow': 'checkout'},
      {'code': 'naverpay', 'flow': 'checkout'},
      {'code': 'tosspay', 'flow': 'checkout'},
    ])
    ..reply('GET', '/me/payment-methods/setup', {'enabled': false});
  stockCustomerApi(
    fake,
    coupons: [
      couponJson(id: 'c1', name: 'welcome', amount: 15000),
      couponJson(id: 'c2', name: 'welcome', amount: 5000),
      couponJson(id: 'c3', name: 'welcome', amount: 5000, usedBookingId: 'b1'),
    ],
  );
  return fake;
}

void main() {
  final brand = BrandConfig.placeholder.name;

  setUp(() => PackageInfo.setMockInitialValues(
        appName: 'customer',
        packageName: 'com.malkkeum.customer',
        version: '1.4.2',
        buildNumber: '7',
        buildSignature: '',
      ));

  testWidgets('header shows the name, the brand greeting and the coupon and points counts', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const MoreTab());
    await app.loadAll();
    await settle(tester);

    expect(find.text('지민'), findsOneWidget);
    expect(find.text(koT.moreGreeting(brand)), findsOneWidget);
    final coupons = find.ancestor(of: find.text(koT.moreCoupons), matching: find.byType(InkWell)).first;
    expect(find.descendant(of: coupons, matching: find.text('2')), findsOneWidget, reason: 'only usable coupons count');
    expect(find.text(koT.walletPoints('1200')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('points counter shows a dash when the wallet cannot be read', (tester) async {
    setViewport(tester, _tall);
    final fake = FakeApi()..reply('GET', '/me/points', {'error': {'code': 'internal'}}, status: 500);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const MoreTab());
    await app.loadAll();
    await settle(tester);

    expect(app.points, isNull);
    expect(find.text('-'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('menu rows follow the brief order and the version row shows the build version', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const MoreTab());
    await app.loadAll();
    await settle(tester);

    final rows = [
      koT.moreScope,
      koT.morePayments,
      koT.moreAddresses,
      koT.moreAccount,
      koT.moreNotices,
      koT.moreBrandTips(brand),
      koT.moreFaq,
      koT.moreContact,
      koT.moreVersionInfo,
    ];
    final tops = [for (final r in rows) tester.getTopLeft(find.widgetWithText(ListTile, r)).dy];
    expect(tops, [...tops]..sort(), reason: 'rows are in the brief order');
    final others = tester.getTopLeft(find.widgetWithText(ListTile, koT.moreLanguage)).dy;
    expect(tops.last, lessThan(others), reason: 'the brief rows come before the second group');

    final version = find.widgetWithText(ListTile, koT.moreVersionInfo);
    expect(find.descendant(of: version, matching: find.text('1.4.2')), findsOneWidget);
    expect(find.text(koT.deleteAccount), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('payment methods list the server channels with text wordmark badges and no logo images', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    await app.loadMethods();
    await pumpUntilFound(tester, find.text(koT.payAvailableTitle));

    for (final (code, wordmark) in [('kakaopay', 'kakaopay'), ('naverpay', 'NAVER pay'), ('tosspay', 'toss pay')]) {
      final row = find.byKey(ValueKey('channel-$code'));
      expect(find.descendant(of: row, matching: find.text(koT.payMethod(code))), findsOneWidget);
      final badge = find.descendant(of: row, matching: find.byType(PayBrandBadge));
      expect(find.descendant(of: badge, matching: find.text(wordmark)), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('channel-card')), findsOneWidget);
    // Our own 3D art (Icon3D) is allowed; any other image would be third-party logo artwork.
    expect(
      find.byWidgetPredicate((w) => w is Image && !(w.image is AssetImage && (w.image as AssetImage).assetName.contains('icons3d/'))),
      findsNothing,
      reason: 'no third-party logo artwork',
    );
    expect(find.text(koT.apPayManageTitle), findsNothing, reason: 'nothing to register without PortOne');
    await unmount(tester);
  });

  testWidgets('account shows the linked Kakao login, phone and email', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const AccountScreen());
    await app.loadProfile();
    await settle(tester);

    expect(find.text('${koT.accountLoginKakao} · ${koT.accountLoginPhone}'), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text('jimin@example.com'), findsOneWidget);
    await unmount(tester);
  });
}
