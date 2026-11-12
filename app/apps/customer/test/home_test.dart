import 'package:core/core.dart';
import 'package:customer/screens/home.dart';
import 'package:customer/screens/more.dart';
import 'package:customer/screens/quote_flow.dart';
import 'package:customer/screens/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

const _hero = '첫 청소 15,000원 웰컴쿠폰';
const _pick = '입주 청소, 이사 전 청소까지 한 번에';
const _news = '원룸 청소 서비스 지역 확대';
const _tip = '에어컨 냄새의 원인은?';

/// Tall enough that the whole home list is built, so section order can be read off the screen.
const _tallPhone = Size(390, 2600);

/// Console content per kind, the way the public `/content?kind=` endpoint filters it.
/// Register before [stockCustomerApi]: the first matching route wins.
void _stockContent(FakeApi fake) {
  fake.onGet('/content', (call) => switch (call.query['kind']) {
    'banner' => [
      contentJson(id: 'b-1', kind: 'banner', title: const {'ko': _hero}, link: 'coupons'),
      contentJson(id: 'b-2', kind: 'banner', title: const {'ko': _pick}, link: 'service/move_in'),
    ],
    'news' => [contentJson(id: 'n-1', kind: 'news', title: const {'ko': _news})],
    'tip' => [contentJson(id: 't-1', kind: 'tip', title: const {'ko': _tip})],
    _ => const <Json>[],
  });
}

double _top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text).first).dy;

void main() {
  testWidgets('home greets the customer by name and shows 7 service tiles with prices', (tester) async {
    setViewport(tester, phoneSize);
    final handle = tester.ensureSemantics();
    final fake = FakeApi();
    stockCustomerApi(fake, name: '지민');
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.homeGreeting('지민')));
    // Services arrive after the greeting; wait for the tiles' price tags before reading them.
    await pumpUntilFound(tester, find.text(koT.fromPrice(formatWon(45000, 'ko'))));
    await settle(tester); // let the stagger fade finish; faded-out tiles drop out of semantics

    final single = catalogCodes.where((c) => !c.startsWith('move_')).toList();
    for (final code in single) {
      // The tile merges its name, short label and price into one label, so match the name prefix.
      final name = RegExp('^${RegExp.escape(koT.service(code))}');
      expect(find.bySemanticsLabel(name), findsWidgets, reason: 'tile for $code');
    }
    // Move-in and move-out share one tile: 6 + 1 = the brief's 7 categories.
    expect(find.bySemanticsLabel(RegExp('^${RegExp.escape(koT.dhSvcMove)}')), findsWidgets);
    expect(find.text(koT.dhSvcMoveShort), findsOneWidget);
    expect(find.text(koT.serviceShort('move_in')), findsNothing);
    expect(find.text(koT.serviceShort('move_out')), findsNothing);
    expect(find.byType(Tag), findsNWidgets(single.length + 1));

    // Tile tags: cheapest unit / fixed price with the "from" wording, the quote tile gets the badge.
    expect(find.text(koT.fromPrice(formatWon(45000, 'ko'))), findsNWidgets(2), reason: 'studio + kitchen');
    expect(find.text(koT.fromPrice(formatWon(39000, 'ko'))), findsOneWidget, reason: 'bathroom');
    expect(find.text(koT.fromPrice(formatWon(59000, 'ko'))), findsNWidgets(2), reason: 'mattress + sofa');
    expect(find.text(koT.fromPrice(formatWon(79000, 'ko'))), findsOneWidget, reason: 'aircon');
    expect(find.text(koT.quoteBadge), findsOneWidget, reason: 'merged move tile');
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('the move tile asks move-in or move-out and opens that quote flow', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.dhSvcMoveShort));
    await settle(tester);
    await tester.tap(find.text(koT.dhSvcMoveShort));
    await settle(tester, duration: const Duration(milliseconds: 600));

    expect(find.text(koT.dhMovePickTitle), findsOneWidget);
    expect(find.text(koT.service('move_out')), findsOneWidget);
    await tester.tap(find.text(koT.service('move_in')));
    await settle(tester);

    expect(find.text(koT.dhMovePickTitle), findsNothing, reason: 'sheet closed');
    final flow = tester.widget<QuoteFlowScreen>(find.byType(QuoteFlowScreen));
    expect(flow.service.code, 'move_in');
    await unmount(tester);
  });

  testWidgets('home order is banner, grid, recommended, news, tips, all from console content', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi();
    _stockContent(fake);
    stockCustomerApi(fake, coupons: [couponJson(id: 'cp-1', name: 'welcome_any', amount: 15000)]);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_tip));
    await settle(tester);

    final order = [
      _top(tester, _hero),
      _top(tester, koT.homeServices),
      _top(tester, koT.dhHomeRecommended),
      _top(tester, _pick),
      _top(tester, koT.dhHomeNews),
      _top(tester, _news),
      _top(tester, koT.moreTips),
      _top(tester, _tip),
    ];
    expect(order, orderedEquals([...order]..sort()), reason: 'top to bottom: $order');
    // The banner is the console's copy plus the customer's own coupon count; the service link is
    // a recommendation, never a second banner.
    expect(find.text(koT.couponAvailable('1')), findsOneWidget);
    expect(find.text(_pick), findsOneWidget);
    for (final kind in ['banner', 'news', 'tip']) {
      expect(fake.callsTo('GET', '/content').where((c) => c.query['kind'] == kind), isNotEmpty, reason: kind);
    }

    await tester.tap(find.text(_news));
    await settle(tester);
    expect(tester.widget<ContentDetailScreen>(find.byType(ContentDetailScreen)).item.id, 'n-1');
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text(_pick));
    await settle(tester);
    expect(tester.widget<ServiceScreen>(find.byType(ServiceScreen)).service.code, 'move_in');
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text(_hero));
    await settle(tester);
    expect(find.byType(CouponsScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('empty content hides the banner and the rails instead of leaving gaps', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi()..reply('GET', '/content', const <Json>[]);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.dhSvcMoveShort));
    await settle(tester);

    expect(find.text(koT.dhHomeNews), findsNothing);
    expect(find.text(koT.dhHomeRecommended), findsNothing);
    expect(find.text(koT.moreCoupons), findsNothing, reason: 'no banner and no usable coupon');
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('a guest sees the banner, 7 tiles and the rails without any account call', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi();
    _stockContent(fake);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake, signedIn: false);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_tip));
    await settle(tester);

    expect(find.text(_hero), findsOneWidget);
    expect(find.byType(Tag), findsNWidgets(7));
    expect(find.text(_pick), findsOneWidget);
    expect(find.text(_news), findsOneWidget);
    expect(fake.callsTo('GET', '/me'), isEmpty);
    expect(fake.callsTo('GET', '/bookings'), isEmpty);
    expect(fake.callsTo('GET', '/me/coupons'), isEmpty);
    await unmount(tester);
  });

  testWidgets('home falls back to the anonymous greeting when the profile has no name', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, name: '');
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(timeGreeting(koT, DateTime.now())));
    expect(find.text(koT.homeServices), findsOneWidget);
    await unmount(tester);
  });
}
