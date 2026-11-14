import 'package:core/core.dart';
import 'package:customer/screens/move_chooser.dart';
import 'package:customer/screens/quote_flow.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// The server's estimate; the screens only render it.
const _estimate = {
  'base': 300000,
  'extras': 0,
  'surcharge_bps': 0,
  'peak_bps': 0,
  'peak': 0,
  'before_vat': 300000,
  'addons': 0,
  'addon_discount_bps': 0,
  'total': 300000,
  'deposit': 30000,
  'deposit_bps': 1000,
};

/// Whole-home is not in the catalogue fixture yet, so the test builds its service directly.
const _wholeHome = Service(code: 'whole_home', type: PricingType.quote);

Future<FakeApi> _pump(
  WidgetTester tester,
  Widget Function(AppState) home,
) async {
  setViewport(tester, phoneSize);
  final fake = FakeApi()
    ..reply('POST', '/quote/estimate', _estimate)
    ..reply(
      'POST',
      '/bookings',
      bookingJson(
        id: 'bk-home',
        serviceCode: 'move_in',
        status: 0,
        threadId: 'th-1',
        estimate: 300000,
      ),
    )
    ..reply('GET', '/chat/threads/th-1/messages', const <Json>[])
    ..reply('POST', '/chat/threads/th-1/read', null)
    ..reply('GET', '/public/proof', {'reviews': const <Json>[]})
    ..reply('GET', '/slots', [slotJson(8), slotJson(13)]);
  stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 30)]);
  final env = await TestEnv.create(fake: fake);
  final app = AppState(env.api, FakeRealtime(env.api));
  await app.loadAll();
  await tester.pumpWidget(
    CustomerTestHost(env: env, app: app, home: home(app)),
  );
  await settle(tester);
  return fake;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

/// The bar's "다음" (pages stay in the tree while they slide, so the last match is the live one).
Finder _next() => find.widgetWithText(PrimaryButton, koT.next).last;

String _chip(String code, int n, int of) => '${koT.service(code)} · $n/$of';

void main() {
  testWidgets(
    'move-in chooser: 신축 then 아파트 opens the move-in quote with the home set',
    (tester) async {
      final fake = await _pump(tester, (_) => const MoveChooserScreen());

      expect(find.text(koT.hgMoveQuestion), findsOneWidget);
      expect(
        find.text(koT.hgSizeQuestion),
        findsNothing,
        reason: 'size waits for 신축/구축',
      );
      await _tap(tester, find.text(koT.hgNewBuild));
      expect(find.text(koT.hgSizeQuestion), findsOneWidget);
      expect(
        find.text(koT.hgEstimateOnly),
        findsNWidgets(3),
        reason: 'each home says 예상 견적',
      );
      expect(find.text(koT.hgEstimateNote), findsOneWidget);
      await _tap(tester, find.text(koT.hgHomeApartment));

      // The apartment path has no 건물 유형 question and the first page is 1/6 (type).
      expect(find.text(_chip('move_in', 1, 6)), findsOneWidget);
      await _tap(tester, find.text(koT.type_normal_move_in));
      await _tap(tester, _next());
      expect(find.text(_chip('move_in', 2, 6)), findsOneWidget);
      expect(find.text(koT.building_apartment), findsNothing);
      expect(
        find.text(koT.dfLayoutOneHalf),
        findsNothing,
        reason: '아파트 has no 원룸 layout',
      );
      expect(find.text(koT.dfLayoutTwo), findsOneWidget);

      await _tap(tester, find.text(koT.dfLayoutTwo));
      await _tap(tester, find.text(koT.dfHas).last);
      await _tap(tester, _next());
      await _tap(tester, find.text(koT.dfNone).last);
      expect(
        find.text(koT.hgFloorHigh),
        findsOneWidget,
        reason: 'floor shown with no elevator',
      );
      await _tap(tester, find.text(koT.hgFloorLow));
      await _tap(tester, _next());
      await _tap(tester, _next()); // address (preselected) -> date
      await _tap(tester, find.text(koT.dfPmVisit));
      await _tap(tester, _next()); // -> review
      expect(find.text(_chip('move_in', 6, 6)), findsOneWidget);
      await _tap(tester, find.text(koT.dfSubmitRequest));

      final body = fake.lastCall('POST', '/bookings')!.json;
      final answers = body['answers'] as Map<String, dynamic>;
      expect(answers['home_type'], 'apartment');
      expect(answers['building'], 'apartment');
      expect(answers['floor_3_or_higher'], isFalse);
      await unmount(tester);
    },
  );

  testWidgets(
    'whole-home asks 원룸·투룸 then starts the quote at 집 구조 with 1/5 and no type page',
    (tester) async {
      await _pump(tester, (_) => MoveChooserScreen(service: _wholeHome));

      expect(
        find.text(koT.hgMoveQuestion),
        findsNothing,
        reason: 'whole-home skips Q1',
      );
      await _tap(tester, find.text(koT.hgHomeOneTwo));

      expect(find.text(_chip('whole_home', 1, 5)), findsOneWidget);
      expect(
        find.byType(CircleChoice),
        findsNothing,
        reason: 'the cleaning type page is skipped',
      );
      expect(
        find.text(koT.building_apartment),
        findsNothing,
        reason: 'the home answers 건물 유형',
      );
      expect(find.text(koT.dfLayoutOneHalf), findsOneWidget);
      expect(
        find.text(koT.dfLayoutFour),
        findsNothing,
        reason: '원룸·투룸 has no 4+ room layout',
      );
      await unmount(tester);
    },
  );

  testWidgets('a quote entered without a home still asks 건물 유형 and every 구조', (
    tester,
  ) async {
    await _pump(
      tester,
      (app) => QuoteFlowScreen(service: app.service('move_out')!),
    );
    expect(find.text(_chip('move_out', 1, 6)), findsOneWidget);
    await _tap(tester, find.text(koT.type_standard));
    await _tap(tester, _next());
    expect(find.text(koT.building_apartment), findsOneWidget);
    expect(find.text(koT.dfLayoutFour), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('errors show only after "다음" is pressed on the basics page', (
    tester,
  ) async {
    await _pump(
      tester,
      (app) => QuoteFlowScreen(service: app.service('move_out')!),
    );
    await _tap(tester, find.text(koT.type_standard));
    await _tap(tester, _next());
    expect(find.text(koT.dfPleaseSelect), findsNothing);
    await _tap(tester, _next());
    expect(find.text(koT.dfPleaseSelect), findsNWidgets(3));
    await unmount(tester);
  });
}
