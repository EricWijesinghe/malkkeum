import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:customer/screens/more.dart';
import 'package:customer/screens/payments.dart';
import 'package:customer/screens/service_scope.dart';
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
    ..reply('GET', '/me', {'name': '지민', 'phone': '01012345678', 'email': 'jimin@example.com', 'logins': ['kakao'], 'created_at': '2026-11-09T03:00:00Z'})
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

    expect(find.text(koT.moreNameSuffix('지민')), findsOneWidget);
    expect(find.text(koT.moreGreeting(brand)), findsOneWidget);
    expect(find.text(koT.moreCouponCount('2')), findsOneWidget, reason: 'only usable coupons count');
    expect(find.text(koT.walletPoints('1200')), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing, reason: 'no avatar on the More header');
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

  testWidgets('menu rows follow the design groups and the version card shows the build version', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const MoreTab());
    await app.loadAll();
    await settle(tester);

    final rows = [
      koT.moreScope,
      koT.morePayments,
      koT.moreCoupons,
      koT.morePoints,
      koT.moreAccount,
      koT.moreAddresses,
      koT.moreNotices,
      koT.moreBrandTips(brand),
      koT.moreFaq,
      koT.moreContact,
      koT.morePartner,
      koT.moreVersionInfo,
    ];
    // Coupons and points also label the header strip: the menu row is the last match.
    final tops = [for (final r in rows) tester.getTopLeft(find.text(r).last).dy];
    expect(tops, [...tops]..sort(), reason: 'rows are in the design order');
    final others = tester.getTopLeft(find.text(koT.moreLanguage)).dy;
    expect(tops.last, lessThan(others), reason: 'the design rows come before the extra group');

    expect(find.text('v1.4.2'), findsOneWidget);
    expect(find.text(koT.deleteAccount), findsNothing, reason: 'sign-out and delete live on the account page');
    expect(find.text(koT.logout), findsNothing);
    await unmount(tester);
  });

  testWidgets('payment methods list the server channels with text wordmark badges and no logo images', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    await app.loadMethods();
    await pumpUntilFound(tester, find.byKey(const ValueKey('channel-kakaopay')));
    expect(find.text(koT.payCardNote(BrandConfig.placeholder.name)), findsOneWidget);
    expect(find.text(koT.addressHome), findsNothing, reason: 'no home/office tabs on payment methods');

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

  testWidgets('account shows the joined date, the Kakao login, phone, email, sign-out and delete', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const AccountScreen());
    await app.loadProfile();
    await settle(tester);

    expect(find.text(koT.accountJoined('2026.11.09')), findsOneWidget);
    expect(find.text(koT.accountLoginKakao), findsOneWidget);
    expect(find.text(koT.accountLoginPhone), findsOneWidget);
    expect(find.text(koT.change), findsOneWidget, reason: 'phone change link');
    await tester.scrollUntilVisible(find.text(koT.deleteAccount), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(koT.logout), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text('jimin@example.com'), findsOneWidget);
    // Values sit at the row's end like the design, not right after a short label.
    final screenRight = tester.getSize(find.byType(AccountScreen)).width;
    final email = tester.getRect(find.text('jimin@example.com'));
    final kakao = tester.getRect(find.text(koT.accountLoginPhone));
    expect(screenRight - email.right, lessThan(40), reason: 'email at the end: $email');
    expect(screenRight - kakao.right, lessThan(40), reason: 'login badges at the end: $kakao');
    await unmount(tester);
  });

  testWidgets('header counters and the version end at the right edge of their cells', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api());
    final app = await pumpCustomerScreen(tester, env, const MoreTab());
    await app.loadAll();
    await settle(tester);

    final width = tester.getSize(find.byType(MoreTab)).width;
    final version = tester.getRect(find.text('v1.4.2'));
    expect(width - version.right, lessThan(48), reason: 'version value at the card end: $version');
    final points = tester.getRect(find.text(koT.walletPoints('1200')));
    expect(width - points.right, lessThan(56), reason: 'points value at the strip end: $points');
    final coupons = tester.getRect(find.text(koT.moreCouponCount('2')));
    expect(coupons.right, greaterThan(width / 2 - 56), reason: 'coupon value at the end of its half: $coupons');
    await unmount(tester);
  });

  testWidgets('service scope opens the design scope page (floor plan), not the old per-service tabs', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api());
    await pumpCustomerScreen(tester, env, const MoreTab());
    await settle(tester);

    await tester.tap(find.text(koT.moreScope));
    await settle(tester);
    expect(find.byType(ServiceScopeScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a guest sees a sign-in prompt in the profile card, not an empty name', (tester) async {
    setViewport(tester, _tall);
    final env = await TestEnv.create(fake: _api(), signedIn: false);
    await pumpCustomerScreen(tester, env, const MoreTab());
    await settle(tester);

    expect(find.text(koT.introStart), findsOneWidget);
    await tester.tap(find.text(koT.introStart));
    await settle(tester);
    expect(find.text(koT.guestSheetTitle), findsOneWidget, reason: 'the card opens sign-in');
    await unmount(tester);
  });
}
