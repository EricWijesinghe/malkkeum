import 'package:core/core.dart';
import 'package:customer/screens/content_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Dahae home on the smallest phone we support at large and largest system text, in every
/// language: header toggle, 8 tiles with badges, upcoming booking, recommended, banner pager and the
/// news list. Any RenderFlex overflow or exception fails the test, named with the widget that caused it.
const _smallPhone = Size(320, 568);
const _scales = [1.3, 2.0];
const _scrollSteps = 20;
const _gutter = Offset(3, 300);

/// Long titles in the app language where one exists: content is written per language in the console.
Json _item(String id, String kind, String title, {String? link}) =>
    contentJson(id: id, kind: kind, title: {'ko': title, 'en': title}, link: link);

FakeApi _homeApi() {
  final fake = FakeApi()
    ..onGet('/content', (call) => switch (call.query['kind']) {
      'banner' => [
        _item('b-1', 'banner', 'First cleaning 15,000 KRW welcome coupon for every new customer', link: 'coupons'),
        _item('b-2', 'banner', 'Move-in cleaning including the pre-move-out cleaning', link: 'service/move_in'),
        _item('b-3', 'banner', 'Two-in-one air conditioner cleaning is now open for booking in every district'),
      ],
      'news' => [
        _item('n-1', 'news', 'Studio cleaning service area expansion: Seongnam and Hanam'),
        _item('n-2', 'news', 'Consultation hours'),
      ],
      'tip' => [
        _item('t-1', 'tip', 'What causes air conditioner odours, and how to stop them?'),
        _item('t-2', 'tip', 'Limescale'),
      ],
      _ => [_item('c-1', 'notice', 'Maintenance')],
    });
  fake.reply('GET', '/services', [
    for (final code in catalogCodes)
      {
        ...serviceJson(code),
        'content': {
          if (code == 'mattress') 'badge': 'new',
          if (code == 'aircon') 'badge': 'hot',
        },
      },
  ]);
  stockCustomerApi(
    fake,
    name: 'Nguyễn Thị Phương Thảo',
    coupons: [couponJson(id: 'cp-1', name: 'welcome_any', amount: 15000)],
    bookings: [bookingJson(id: 'b1', status: 0, serviceCode: 'move_out', estimate: 420000)],
    feed: [
      {'kind': 'seasonal', 'score': 10, 'service': 'aircon', 'reason': 'summer_aircon', 'facts': 0},
      {'kind': 'resume_quote', 'score': 9, 'service': 'move_in', 'reason': 'draft_unfinished', 'facts': 0},
    ],
  );
  return fake;
}

void main() {
  for (final locale in LocaleController.supported) {
    final code = locale.languageCode;
    for (final scale in _scales) {
      testWidgets('[$code x$scale] home fits a small phone from header to news', (tester) async {
        setViewport(tester, _smallPhone);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final t = lookupT(locale);
        final env = await TestEnv.create(fake: _homeApi(), localeCode: code);

        // Capture layout errors with their widget details (the test binding keeps only the bare message).
        final saved = FlutterError.onError;
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = saved);

        await pumpCustomerApp(tester, env);
        await pumpUntilFound(tester, find.text(t.tabHome));
        await settle(tester, duration: const Duration(milliseconds: 600));

        // The toggle swaps the page for the recommendations and back.
        await tester.tap(find.text(t.dhHomePick(BrandConfig.placeholder.name)));
        await settle(tester, duration: const Duration(milliseconds: 600));
        expect(find.text(t.dhHomeRecommended), findsOneWidget);
        expect(find.text(t.service('sofa')), findsNothing);
        await tester.tap(find.text(t.dhHomeAll));
        await settle(tester, duration: const Duration(milliseconds: 600));
        expect(find.text(t.service('sofa')), findsOneWidget);

        var sawBanner = false, sawNews = false;
        for (var i = 0; i < _scrollSteps; i++) {
          await tester.dragFrom(_gutter, const Offset(0, -260)); // start in the gutter, on no tile
          await settle(tester, duration: const Duration(milliseconds: 300));
          sawBanner |= find.byType(BannerCarousel).evaluate().isNotEmpty;
          sawNews |= find.text(t.dhHomeNews).evaluate().isNotEmpty;
        }
        FlutterError.onError = saved;
        final where = RegExp(r'file:///[^\s)]+/(?:customer/lib|ui/lib)/[^\s)]+');
        final failures = {
          for (final d in errors)
            '${d.exceptionAsString().split('\n').first} @ '
                '${where.allMatches(d.toString()).map((m) => m.group(0)).take(3).join(' ')}',
        };
        expect(failures, isEmpty, reason: failures.join('\n'));
        expect((sawBanner, sawNews), (true, true), reason: 'the banner and the news list were built');
        await unmount(tester);
      });
    }
  }
}
