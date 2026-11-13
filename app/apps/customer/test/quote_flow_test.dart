import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/chat.dart';
import 'package:customer/screens/quote_flow.dart';
import 'package:customer/screens/request_status.dart';
import 'package:customer/screens/service.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Pages stay in the tree while they slide, so "Next" can match twice; the bar is the last.
Finder _next() => find.widgetWithText(PrimaryButton, koT.next).last;

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

/// The server's estimate; the screens only render it.
const _estimate = {
  'base': 300000,
  'extras': 0,
  'surcharge_bps': 0,
  'peak_bps': 0,
  'peak': 0,
  'before_vat': 300000,
  'addons': 71100,
  'addon_discount_bps': 1000,
  'total': 401100,
  'deposit': 40100,
  'deposit_bps': 1000,
};

Future<FakeApi> _pumpMoveOut(WidgetTester tester) async {
  setViewport(tester, phoneSize);
  final fake = FakeApi()
    ..reply('POST', '/quote/estimate', _estimate)
    ..reply(
      'POST',
      '/bookings',
      bookingJson(
        id: 'bk-quote',
        serviceCode: 'move_out',
        status: 0,
        threadId: 'th-1',
        estimate: 401100,
      ),
    )
    ..reply('GET', '/chat/threads/th-1/messages', const <Json>[])
    ..reply('POST', '/chat/threads/th-1/read', null)
    ..reply('GET', '/public/proof', {
      'reviews': [
        {'booking_id': 'b', 'rating': 5, 'body': '정말 깨끗해졌어요', 'name': '김**'},
      ],
    })
    ..reply('GET', '/slots', [slotJson(8), slotJson(13)]);
  stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 30)]);
  final env = await TestEnv.create(fake: fake);
  final app = AppState(env.api, FakeRealtime(env.api));
  await app.loadAll();
  await tester.pumpWidget(
    CustomerTestHost(
      env: env,
      app: app,
      home: QuoteFlowScreen(service: app.service('move_out')!),
    ),
  );
  await settle(tester);
  return fake;
}

String _chip(int n) => '${koT.service('move_out')} · $n/7';

void main() {
  test('every cleaning type shows its own 3D art, never the fallback plate', () {
    const types = [
      'standard',
      'same_day_move',
      'some_luggage_left',
      'normal_move_in',
      'after_interior',
      'lived_in_deep_clean',
    ];
    for (final c in types) {
      expect(Icon3DRegistry.has(cleaningTypeIcon(c)), isTrue, reason: c);
    }
  });

  testWidgets(
    'move-out quote: seven steps, AC add-on, Safe booking, review, then the request status opens',
    (tester) async {
      final fake = await _pumpMoveOut(tester);

      // 1/7: three cleaning circles, the 짐 상태 radio list (5), reviews from /public/proof.
      expect(find.text(_chip(1)), findsOneWidget);
      expect(find.byType(CircleChoice), findsNWidgets(3));
      expect(find.text(koT.luggage_not_unpacked), findsOneWidget);
      expect(find.byType(RadioRow), findsNWidgets(5));
      await _tap(tester, find.text(koT.type_standard));
      await _tap(tester, find.text(koT.luggage_partly_unpacked));
      expect(find.text('정말 깨끗해졌어요'), findsOneWidget);
      await _tap(tester, _next());

      // 2/7: four buildings, room structure, duplex marked until answered.
      expect(find.text(_chip(2)), findsOneWidget);
      for (final b in [
        koT.building_apartment,
        koT.building_officetel,
        koT.dfBldVillaHouse,
        koT.building_commercial,
      ]) {
        expect(find.text(b), findsOneWidget);
      }
      expect(
        find.text(koT.dfPleaseSelect),
        findsOneWidget,
        reason: 'only 복층 is marked from the start (design p15)',
      );
      // "다음" stays tappable but points at what is missing instead of advancing.
      await _tap(tester, _next());
      expect(find.text(_chip(2)), findsOneWidget);
      expect(
        find.text(koT.dfPleaseSelect),
        findsNWidgets(3),
        reason: 'building, room structure and duplex are all unanswered',
      );
      await _tap(tester, find.text(koT.building_commercial));
      await _tap(tester, find.text(koT.dfLayoutTwo));
      await _tap(tester, find.text(koT.dfHas).last);
      expect(find.text(koT.dfPleaseSelect), findsNothing);
      await _tap(tester, _next());

      // 3/7: counters 0-5, the elevator, the 3층 checkbox.
      expect(find.text(_chip(3)), findsOneWidget);
      await _tap(tester, find.bySemanticsLabel(koT.dfCountN('2')).first);
      await _tap(tester, find.text(koT.dfNone).last);
      await _tap(tester, find.text(koT.dfFloor3));
      await _tap(tester, _next());

      // 4/7: the address (preselected) as a radio list.
      expect(find.text(_chip(4)), findsOneWidget);
      expect(find.text(koT.dfAddressTitle), findsOneWidget);
      await _tap(tester, _next());

      // 5/7: date, AM/PM arrival cards, AC add-on with catalog prices.
      expect(find.text(_chip(5)), findsOneWidget);
      expect(find.text(koT.dfAmVisit), findsOneWidget);
      expect(find.text(koT.dfPmVisit), findsOneWidget);
      await _tap(tester, find.text(koT.dfPmVisit));
      // No aircon coupon in the wallet: "쿠폰받기" opens the add-on sheet.
      await _tap(tester, find.text(koT.dfAcCouponCta));
      final wall = find.widgetWithText(
        CountStepper,
        '${koT.unit('wall')} · ${formatWon(79000, 'ko')}',
      );
      expect(wall, findsOneWidget, reason: 'price comes from the catalog');
      await tester.tap(
        find.descendant(of: wall, matching: find.byTooltip('+')),
      );
      await settle(tester);
      Navigator.of(tester.element(wall)).pop();
      await settle(tester);
      expect(find.text(koT.dfAcAddonAdded('1')), findsOneWidget);
      await _tap(tester, _next());

      // 6/7: 다해 안심예약 with the server estimate and the deposit rate.
      expect(find.text(_chip(6)), findsOneWidget);
      expect(find.text(koT.dfSafeBooking), findsOneWidget);
      expect(find.text(koT.dfDepositNote('10')), findsOneWidget);
      await _tap(tester, _next());

      // 7/7: review sections with 변경, payment info, notes.
      expect(find.text(_chip(7)), findsOneWidget);
      expect(
        find.text(koT.dfChange, skipOffstage: false),
        findsNWidgets(3),
        reason: 'home, basic and space info can each be changed',
      );
      // The payment section sits below the fold of the lazy list.
      await tester.scrollUntilVisible(
        find.text(koT.quoteNoPayNow),
        200,
        scrollable: find
            .descendant(
              of: find.byType(QuoteReviewPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(koT.dfEstAddons('10')), findsOneWidget);
      expect(
        find.text(formatWon(40100, 'ko')),
        findsOneWidget,
        reason: 'deposit preview from the server',
      );
      expect(find.text(koT.quoteNoPayNow), findsOneWidget);
      // 변경 on 공간 정보 goes back to step 3.
      await _tap(tester, find.text(koT.dfChange).last);
      expect(find.text(_chip(3)), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await _tap(tester, _next());
      }
      expect(find.text(_chip(7)), findsOneWidget);

      final estimateCall = fake.lastCall('POST', '/quote/estimate')!.json;
      expect(estimateCall['ac_addons'], [
        {'unit': 'wall', 'count': 1},
      ]);
      await _tap(tester, find.text(koT.dfSubmitRequest));

      final body = fake.lastCall('POST', '/bookings')!.json;
      // The preview is priced for the same slot the booking takes (peak surcharge included).
      expect(estimateCall['visit_date'], body['visit_date']);
      expect(estimateCall['start_hour'], body['start_hour']);
      expect(body['service_code'], 'move_out');
      expect(body['start_hour'], 13);
      final answers = body['answers'] as Map<String, dynamic>;
      expect(answers['cleaning_type'], 'standard');
      expect(answers['luggage'], 'partly_unpacked');
      expect(answers['building'], 'commercial');
      expect(answers['layout'], 'two_rooms');
      expect(answers['duplex'], isTrue);
      expect(answers['bathrooms'], 2);
      expect(answers['balconies'], 0);
      expect(answers['elevator'], isFalse);
      expect(answers['floor_3_or_higher'], isTrue);
      expect(answers['ac_addons'], [
        {'unit': 'wall', 'count': 1},
      ]);

      // p20 + p21: the request status with the completion sheet; "상담 채팅 보기" opens the chat.
      expect(find.byType(RequestStatusScreen), findsOneWidget);
      expect(find.text(koT.dfRequestDone), findsOneWidget);
      expect(find.text(koT.dfAcUpsellCta), findsOneWidget);
      await _tap(tester, find.text(koT.dfViewChat));
      expect(find.byType(ChatRoomScreen), findsOneWidget);
      expect(
        tester.widget<ChatRoomScreen>(find.byType(ChatRoomScreen)).bookingId,
        'bk-quote',
      );
      await unmount(tester);
    },
  );

  testWidgets(
    'the first quote step cannot advance until the cleaning type is chosen',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake);
      await pumpCustomerScreen(
        tester,
        env,
        ServiceScreen(service: Service.fromJson(serviceJson('move_in'))),
      );
      await settle(tester);

      expect(
        find.byType(QuoteFlowScreen),
        findsOneWidget,
        reason: 'quote services start at step 1',
      );
      expect(tester.widget<PrimaryButton>(_next()).onPressed, isNull);
      await _tap(tester, find.text(koT.type_normal_move_in));
      expect(tester.widget<PrimaryButton>(_next()).onPressed, isNotNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'AC banner: "쿠폰받기" takes the console-issued aircon coupon first, then adds units',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(
        fake,
        coupons: [
          couponJson(id: 'any', name: 'welcome', amount: 5000),
          couponJson(id: 'ac', name: 'ac', amount: 7000, serviceCode: 'aircon'),
          couponJson(
            id: 'ac-used',
            name: 'ac',
            amount: 9000,
            serviceCode: 'aircon',
            usedBookingId: 'bk-old',
          ),
        ],
      );
      final env = await TestEnv.create(fake: fake);
      final app = AppState(env.api, FakeRealtime(env.api));
      await app.loadAll();
      final answers = QuoteAnswers();
      await tester.pumpWidget(
        CustomerTestHost(
          env: env,
          app: app,
          home: Scaffold(
            body: AcAddonBanner(
              aircon: app.service('aircon')!,
              answers: answers,
              onChanged: () {},
            ),
          ),
        ),
      );
      await settle(tester);

      expect(
        find.text(koT.dfAcCouponTitle(formatWon(7000, 'ko'))),
        findsOneWidget,
        reason: 'the amount is the usable aircon coupon, not a built-in number',
      );
      await _tap(tester, find.text(koT.dfAcCouponCta));
      expect(find.text(koT.dfAcCouponClaimed), findsOneWidget);
      expect(find.byType(CountStepper), findsNothing);
      expect(find.text(koT.dfAcCouponCta), findsNothing);

      await _tap(tester, find.text(koT.dfAcAddonAdd));
      expect(find.byType(CountStepper), findsWidgets);
      await tester.tap(find.byTooltip('+').first);
      await settle(tester);
      Navigator.of(tester.element(find.byType(CountStepper).first)).pop();
      await settle(tester);
      expect(find.text(koT.dfAcAddonAdded('1')), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'reduced motion: the quote steps switch at once and leave no ticker running',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      // Idle icon loops on, as in the real app: reduced motion alone must hold them still.
      Icon3D.idleMotion = true;
      addTearDown(() => Icon3D.idleMotion = false);
      await _pumpMoveOut(tester);
      expect(tester.hasRunningAnimations, isFalse, reason: 'step 1 at rest');

      /// Past the framework's own ink splash and button fade, nothing may still be ticking.
      Future<void> rest(String what) async {
        await settle(tester);
        expect(tester.hasRunningAnimations, isFalse, reason: what);
      }

      await tester.tap(find.text(koT.type_standard));
      await rest('cleaning type chosen');
      await tester.tap(_next());
      await tester.pump();
      await tester.pump();
      expect(find.text(_chip(2)), findsOneWidget);
      expect(find.text(_chip(1)), findsNothing, reason: 'no page slide');
      await rest('step 2');

      // A blocked "다음" marks the missing answers without moving anything.
      await tester.tap(_next());
      await tester.pump();
      expect(find.text(koT.dfPleaseSelect), findsNWidgets(3));
      await rest('blocked next');
      await unmount(tester);
    },
  );

  testWidgets('request status shows the tracker and cancels a consultation', (
    tester,
  ) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('POST', '/bookings/bk-q/cancel', {'ok': true});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    final booking = Booking.fromJson(
      bookingJson(
        id: 'bk-q',
        serviceCode: 'move_out',
        status: 0,
        estimate: 346500,
        threadId: 'th-1',
        address: addressJson(),
        answers: {
          'cleaning_type': 'standard',
          'building': 'apartment',
          'layout': 'two_rooms',
        },
      ),
    );
    await pumpCustomerScreen(
      tester,
      env,
      RequestStatusScreen(booking: booking, estimate: _estimate),
    );
    await settle(tester);

    expect(find.text(koT.dfRequested), findsOneWidget);
    // The tracker speaks the bookings list's words (design p20).
    for (final s in [
      koT.bkStepConsult,
      koT.bkStepConfirmed,
      koT.bkStepMatched,
      koT.bkStepCompleted,
    ]) {
      expect(find.text(s), findsOneWidget);
    }
    expect(find.text(formatWon(346500, 'ko')), findsOneWidget);
    expect(find.text(koT.dfAwaitingPay), findsOneWidget);
    expect(find.text(koT.dfPayInfoBody('10')), findsOneWidget);
    await tester.scrollUntilVisible(find.text(koT.cancelBooking), 200, scrollable: find.byType(Scrollable).first);
    await _tap(tester, find.text(koT.cancelBooking));
    await _tap(tester, find.widgetWithText(FilledButton, koT.cancelBooking));
    expect(
      fake.lastCall('POST', '/bookings/bk-q/cancel')!.json['accepted_fee'],
      0,
    );
    await unmount(tester);
  });
}
