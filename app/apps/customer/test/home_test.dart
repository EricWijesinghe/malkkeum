import 'package:core/core.dart';
import 'package:customer/screens/content_rail.dart';
import 'package:customer/screens/home.dart';
import 'package:customer/screens/more.dart';
import 'package:customer/screens/request_status.dart';
import 'package:customer/screens/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

const _hero = '첫 청소 웰컴 쿠폰팩 즉시 지급';
const _cardLabel = '웰컴 혜택';
const _cardValue = '15,000원';
const _hero2 = '에어컨 2in1 청소 예약 오픈';
const _pick = '이사 전 퇴거 청소까지';
const _pickLine = '이사 청소 · 상담 후 견적';
const _notice = '[원룸 청소] 서비스 지역 확대 안내';
const _news = '10평 원룸, 2시간이면 어디까지 청소될까요?';
const _tip = '에어컨 냄새의 원인은 필터가 아니에요';

/// Tall enough that the whole home page is laid out, so section order can be read off the screen.
const _tallPhone = Size(390, 2600);

final _brand = BrandConfig.placeholder.name;

/// Console content per kind, the way the public `/content?kind=` endpoint filters it.
/// Register before [stockCustomerApi]: the first matching route wins.
void _stockContent(FakeApi fake) {
  fake.onGet('/content', (call) => switch (call.query['kind']) {
    'banner' => [
      {
        ...contentJson(id: 'b-1', kind: 'banner', title: const {'ko': _hero}, link: 'coupons'),
        'body': {
          'card': {
            'label': {'ko': _cardLabel},
            'value': {'ko': _cardValue},
          },
        },
      },
      {
        ...contentJson(id: 'b-2', kind: 'banner', title: const {'ko': _pick}, link: 'service/move_out'),
        'body': {
          'text': {'ko': _pickLine},
        },
      },
      contentJson(id: 'b-3', kind: 'banner', title: const {'ko': _hero2}),
    ],
    'notice' => [contentJson(id: 'c-1', title: const {'ko': _notice})],
    'news' => [
      {
        ...contentJson(id: 'n-1', kind: 'news', title: const {'ko': _news}),
        'body': {'service': 'studio'},
      },
    ],
    'tip' => [contentJson(id: 't-1', kind: 'tip', title: const {'ko': _tip})],
    _ => const <Json>[],
  });
}

/// The catalogue in the owner's tile order, with the seeded N / HOT badges.
void _stockBadges(FakeApi fake) => fake.reply('GET', '/services', [
  for (final code in _tileOrder)
    {
      ...serviceJson(code),
      'content': {
        if (code == 'mattress') 'badge': 'new',
        if (code == 'aircon') 'badge': 'hot',
      },
    },
]);

const _tileOrder = ['studio', 'move_out', 'move_in', 'bathroom', 'kitchen', 'mattress', 'aircon', 'sofa'];

/// Home shows the greeting on one line.
String _oneLine(String greeting) => greeting.replaceAll('\n', ' ');

double _top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text).first).dy;

void main() {
  testWidgets('home shows the logo, the greeting and 8 plain tiles in catalogue order with N and HOT', (tester) async {
    setViewport(tester, phoneSize);
    final handle = tester.ensureSemantics();
    final fake = FakeApi();
    _stockBadges(fake);
    stockCustomerApi(fake, name: '지민');
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_oneLine(koT.homeGreeting('지민'))));
    await pumpUntilFound(tester, find.text(koT.service('sofa')));
    await settle(tester); // let the stagger finish; faded-out tiles drop out of semantics

    expect(find.byType(DahaeLogo), findsOneWidget);
    final spots = [for (final code in _tileOrder) tester.getCenter(find.text(koT.service(code)))];
    for (var i = 1; i < spots.length; i++) {
      final sameRow = i % 4 != 0;
      expect(
        sameRow ? spots[i].dx > spots[i - 1].dx : spots[i].dy > spots[i - 1].dy,
        isTrue,
        reason: '${_tileOrder[i]} follows ${_tileOrder[i - 1]}',
      );
    }
    // Move-in and move-out are their own tiles again, and no tile carries a price or a short name.
    expect(find.byType(Tag), findsNothing);
    expect(find.textContaining(koT.fromPrice('')), findsNothing);
    expect(find.text(koT.serviceShort('studio')), findsNothing);
    expect(find.text(koT.dhBadgeNew), findsOneWidget);
    expect(find.text(koT.dhBadgeHot), findsOneWidget);
    expect(find.bySemanticsLabel('${koT.service('mattress')}, ${koT.dhBadgeNew}'), findsOneWidget);
    expect(find.bySemanticsLabel(koT.service('studio')), findsOneWidget);
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('a move tile opens its own service', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.service('move_in')));
    await settle(tester);
    await tester.tap(find.text(koT.service('move_in')));
    await settle(tester);

    expect(tester.widget<ServiceScreen>(find.byType(ServiceScreen)).service.code, 'move_in');
    await unmount(tester);
  });

  testWidgets('home order is grid, recommended, banner, news; every row opens its target', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi();
    _stockContent(fake);
    stockCustomerApi(fake, coupons: [couponJson(id: 'cp-1', name: 'welcome_any', amount: 15000)]);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_tip));
    await settle(tester);

    final order = [
      _top(tester, koT.service('sofa')),
      _top(tester, koT.dhHomeRecommended),
      _top(tester, _pick),
      _top(tester, _hero),
      _top(tester, koT.dhHomeNews),
      _top(tester, _notice),
      _top(tester, _news),
      _top(tester, _tip),
    ];
    expect(order, orderedEquals([...order]..sort()), reason: 'top to bottom: $order');
    // A banner linking to a service is the recommendation row, never a carousel page.
    expect(find.text(_pick), findsOneWidget);
    expect(find.text(_pickLine), findsOneWidget);
    expect(find.text(koT.dhBannerPage('1', '2')), findsOneWidget);
    // The banner's art card prints the console content's label and value (design p01).
    expect(find.text(_cardLabel), findsOneWidget);
    expect(find.text(_cardValue), findsOneWidget);
    // The banner has no line of its own, so it names the customer's usable coupons.
    expect(find.text(koT.couponAvailable('1')), findsOneWidget);
    // One notice with its tag; the article names its service, the tip its kind.
    expect(find.text(koT.dhNoticeTag), findsOneWidget);
    expect(find.descendant(of: find.byType(NewsList), matching: find.text(koT.service('studio'))), findsOneWidget);
    expect(find.descendant(of: find.byType(NewsList), matching: find.text(koT.moreTips)), findsOneWidget);
    for (final kind in ['banner', 'notice', 'news', 'tip']) {
      expect(fake.callsTo('GET', '/content').where((c) => c.query['kind'] == kind), isNotEmpty, reason: kind);
    }

    await tester.tap(find.text(_news));
    await settle(tester);
    expect(tester.widget<ContentDetailScreen>(find.byType(ContentDetailScreen)).item.id, 'n-1');
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text(_notice));
    await settle(tester);
    expect(tester.widget<ContentDetailScreen>(find.byType(ContentDetailScreen)).item.id, 'c-1');
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text(_pick));
    await settle(tester);
    expect(tester.widget<ServiceScreen>(find.byType(ServiceScreen)).service.code, 'move_out');
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text(_hero));
    await settle(tester);
    expect(find.byType(CouponsScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the banner turns its page by itself and the counter follows', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi();
    _stockContent(fake);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_hero));
    await settle(tester);
    expect(find.text(koT.dhBannerPage('1', '2')), findsOneWidget);

    await settle(tester, duration: const Duration(seconds: 6));
    expect(find.text(koT.dhBannerPage('2', '2')), findsOneWidget);
    expect(tester.getTopLeft(find.text(_hero2)).dx, greaterThanOrEqualTo(0));

    // A swipe back works like any pager.
    await tester.fling(find.byKey(const ValueKey('home-banners')), const Offset(300, 0), 1000);
    await settle(tester, duration: const Duration(seconds: 1));
    expect(find.text(koT.dhBannerPage('1', '2')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('reduced motion keeps the banner on its page and starts no animation', (tester) async {
    setViewport(tester, _tallPhone);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final fake = FakeApi();
    _stockContent(fake);
    _stockBadges(fake);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_hero));
    await settle(tester, duration: const Duration(seconds: 6));

    expect(find.text(koT.dhBannerPage('1', '2')), findsOneWidget);
    expect(find.text(koT.dhBadgeHot), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await unmount(tester);
  });

  testWidgets('PICK shows only the recommendations and the feed; 전체 brings the page back', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi();
    _stockContent(fake);
    stockCustomerApi(
      fake,
      feed: [
        {'kind': 'seasonal', 'score': 10, 'service': 'aircon', 'reason': 'summer_aircon', 'facts': 0},
      ],
    );
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_pick));
    await settle(tester);
    // Home itself shows the top recommendation only.
    expect(find.text(koT.feedTitleSeasonal), findsNothing);

    await tester.tap(find.text(koT.dhHomePick(_brand)));
    await settle(tester);
    expect(find.text(_pick), findsOneWidget);
    expect(find.text(koT.feedTitleSeasonal), findsOneWidget);
    expect(find.text(koT.feedWhySummer), findsOneWidget);
    expect(find.text(koT.service('sofa')), findsNothing);
    expect(find.text(_hero), findsNothing);
    expect(find.text(koT.dhHomeNews), findsNothing);

    // Opening a feed card waits for its haptic; the test shell has no platform to answer it.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text(koT.feedTitleSeasonal));
    await settle(tester);
    expect(tester.widget<ServiceScreen>(find.byType(ServiceScreen)).service.code, 'aircon');
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text(koT.dhHomeAll));
    await settle(tester);
    expect(find.text(koT.service('sofa')), findsOneWidget);
    expect(find.text(_hero), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('empty content hides the banner, the recommendation and the news instead of leaving gaps', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi()..reply('GET', '/content', const <Json>[]);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.service('sofa')));
    await settle(tester);

    expect(find.text(koT.dhHomeNews), findsNothing);
    expect(find.text(koT.dhHomeRecommended), findsNothing);
    expect(find.byType(BannerCarousel), findsNothing, reason: 'no banner and no usable coupon');

    await tester.tap(find.text(koT.dhHomePick(_brand)));
    await settle(tester);
    expect(find.text(koT.noContent), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('the next booking sits right under the grid and a quote in consultation opens its tracker', (tester) async {
    setViewport(tester, _tallPhone);
    final booking = bookingJson(id: 'q-1', status: 0, serviceCode: 'move_in', answers: const {}, estimate: 346500);
    final fake = FakeApi();
    _stockContent(fake);
    stockCustomerApi(fake, bookings: [booking]);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.textContaining(koT.homeUpcoming));
    await settle(tester);

    final order = [
      _top(tester, koT.service('sofa')),
      tester.getTopLeft(find.textContaining(koT.homeUpcoming)).dy,
      _top(tester, koT.dhHomeRecommended),
    ];
    expect(order, orderedEquals([...order]..sort()), reason: 'top to bottom: $order');

    await tester.tap(find.text(koT.bkStepConsult));
    await settle(tester);
    expect(tester.widget<RequestStatusScreen>(find.byType(RequestStatusScreen)).booking.id, 'q-1');
    await unmount(tester);
  });

  testWidgets('a guest sees the banner, 8 tiles and the news without any account call', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi();
    _stockContent(fake);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake, signedIn: false);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(_tip));
    await settle(tester);

    expect(find.text(_hero), findsOneWidget);
    for (final code in catalogCodes) {
      expect(find.text(koT.service(code)), findsWidgets, reason: 'tile for $code');
    }
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
    await pumpUntilFound(tester, find.text(_oneLine(timeGreeting(koT, DateTime.now()))));
    await pumpUntilFound(tester, find.text(koT.service('studio')));
    await unmount(tester);
  });
}
