import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Dahae home (U2) on the smallest phone we support at large and largest system text, in every
/// language: banner, 7 tiles, recommended, news and tips rails, and the move sheet. Any RenderFlex
/// overflow or exception fails the test, named with the widget that caused it.
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
      testWidgets('[$code x$scale] home fits a small phone from banner to tips', (tester) async {
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

        // On this screen the grid starts below the fold: centre the move tile, clear of the bottom bar.
        final list = find.byType(CustomScrollView).first;
        final scrollable = find.descendant(of: list, matching: find.byType(Scrollable)).first;
        final tile = find.text(t.dhSvcMoveShort);
        await tester.scrollUntilVisible(tile, 120, scrollable: scrollable);
        await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
        await settle(tester, duration: const Duration(milliseconds: 400));
        await tester.tap(tile);
        await settle(tester, duration: const Duration(milliseconds: 600));
        expect(find.text(t.dhMovePickTitle), findsOneWidget);
        Navigator.of(tester.element(find.text(t.dhMovePickTitle))).pop();
        await settle(tester, duration: const Duration(milliseconds: 600));

        var sawNews = false, sawTips = false;
        for (var i = 0; i < _scrollSteps; i++) {
          await tester.dragFrom(_gutter, const Offset(0, -260)); // start beside the cards, on no tile
          await settle(tester, duration: const Duration(milliseconds: 300));
          sawNews |= find.text(t.dhHomeNews).evaluate().isNotEmpty;
          sawTips |= find.text(t.moreTips).evaluate().isNotEmpty;
        }
        FlutterError.onError = saved;
        final where = RegExp(r'file:///[^\s)]+/(?:customer/lib|ui/lib)/[^\s)]+');
        final failures = {
          for (final d in errors)
            '${d.exceptionAsString().split('\n').first} @ '
                '${where.allMatches(d.toString()).map((m) => m.group(0)).take(3).join(' ')}',
        };
        expect(failures, isEmpty, reason: failures.join('\n'));
        expect((sawNews, sawTips), (true, true), reason: 'both rails were built while scrolling');
        await unmount(tester);
      });
    }
  }
}
