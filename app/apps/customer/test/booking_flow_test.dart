import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/service.dart';
import 'package:customer/screens/service_scope.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// From the home grid, open a service's detail screen.
Future<void> _openFromHome(WidgetTester tester, String code) async {
  await pumpUntilFound(tester, find.text(koT.service(code)));
  await tester.tap(find.text(koT.service(code)));
  await settle(tester);
}

/// Every slot the schedule asks for is open, unless a test overrides it.
void _openSlots(FakeApi fake, {bool available = true}) {
  fake.reply('GET', '/slots', [
    for (final h in const [8, 9, 13, 14]) slotJson(h, available: available),
  ]);
}

/// The bottom bar's amount (design: price on the left of the action).
Finder _barAmount(int won) => find.descendant(
  of: find.byType(PriceBar),
  matching: find.text(formatWon(won, 'ko')),
);

Future<AppState> _loaded(TestEnv env) async {
  final app = AppState(env.api, FakeRealtime(env.api));
  await app.loadAll();
  return app;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

void main() {
  testWidgets(
    'bathroom unit choice updates the price bar on the service screen',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake);
      await pumpCustomerApp(tester, env);
      await _openFromHome(tester, 'bathroom');

      expect(
        _barAmount(39000),
        findsOneWidget,
        reason: 'first unit is preselected',
      );
      await _tap(tester, find.text(koT.unit('count_3')));
      expect(_barAmount(69000), findsOneWidget);
      expect(_barAmount(39000), findsNothing);
      await unmount(tester);
    },
  );

  testWidgets(
    'studio detail: duration and price cards from the catalog, 5 included items, size note',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake);
      // A console-edited price: the screen must show it, not a built-in number.
      final studio = serviceJson('studio')
        ..['pricing'] = {'type': 'fixed', 'price': 51000, 'minutes': 120};
      await pumpCustomerScreen(
        tester,
        env,
        ServiceScreen(service: Service.fromJson(studio)),
      );
      await settle(tester);

      expect(find.text(koT.dfDuration), findsOneWidget);
      expect(find.text(koT.duration(120)), findsOneWidget);
      expect(
        find.text(formatWon(51000, 'ko')),
        findsNWidgets(2),
        reason: 'price card and bottom bar',
      );
      expect(find.text(koT.dfBookNow), findsOneWidget);
      final list = find.byType(CheckList);
      await tester.ensureVisible(list);
      for (final k in studioScope) {
        expect(
          find.descendant(of: list, matching: find.text(scopeLabel(koT, k))),
          findsOneWidget,
        );
      }
      expect(find.text(koT.dfStudioNote('10')), findsOneWidget);
      await _tap(tester, find.text(koT.moreScope));
      expect(find.byType(ServiceScopeScreen), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'AC shows four 3D unit cards with catalog duration and price; the bar follows the choice',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake);
      final ac = Service.fromJson(serviceJson('aircon'));
      await pumpCustomerScreen(tester, env, ServiceScreen(service: ac));
      await settle(tester);

      expect(find.byType(ChoiceTile3D), findsNWidgets(4));
      for (final u in ac.units) {
        expect(
          find.widgetWithText(ChoiceTile3D, formatWon(u.price, 'ko')),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ChoiceTile3D, koT.duration(u.minutes)),
          findsWidgets,
        );
      }
      await _tap(tester, find.text(koT.unit('two_in_one')));
      expect(_barAmount(ac.units[2].price), findsOneWidget);
      expect(find.text(koT.dfMustCheck), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'one saved address that fits the service skips straight to the date step',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 8)]);
      _openSlots(fake);
      final env = await TestEnv.create(fake: fake);
      await pumpCustomerApp(tester, env);
      await _openFromHome(tester, 'studio');

      await _tap(tester, find.text(koT.dfBookNow));
      expect(find.byType(ScheduleScreen), findsOneWidget);
      expect(find.byType(AddressPickScreen), findsNothing);
      await unmount(tester);
    },
  );

  testWidgets(
    'an address over 10 pyeong cannot be picked: a toast offers a consultation',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(
        fake,
        addresses: [
          addressJson(id: 'a-home', label: '우리집', sizePyeong: 8),
          addressJson(id: 'a-big', label: '본가', sizePyeong: 24),
        ],
      );
      final env = await TestEnv.create(fake: fake);
      final app = await _loaded(env);
      final d = BookingDraft(app.service('studio')!);
      await tester.pumpWidget(
        CustomerTestHost(
          env: env,
          app: app,
          home: AddressPickScreen(draft: d),
        ),
      );
      await settle(tester);

      expect(
        d.address?.id,
        'a-home',
        reason: 'the fitting address is preselected',
      );
      expect(find.text(koT.dfAddressTitle), findsOneWidget);
      await _tap(tester, find.text('본가'));
      expect(d.address?.id, 'a-home', reason: 'too big to select');
      expect(
        find.text(koT.dfStudioToast(koT.service('studio'), '10', '본가', '24')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SnackBarAction, koT.consultCta),
        findsOneWidget,
      );
      expect(find.text(koT.addressAdd), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'the slot sheet marks full hours 마감 and the chosen hour shows on the date step',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()
        ..reply('GET', '/slots', [
          slotJson(8),
          slotJson(9),
          slotJson(13, available: false),
          slotJson(14),
        ]);
      stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 8)]);
      final env = await TestEnv.create(fake: fake);
      final app = await _loaded(env);
      final d = BookingDraft(app.service('studio')!)
        ..address = app.addresses.first;
      await tester.pumpWidget(
        CustomerTestHost(
          env: env,
          app: app,
          home: ScheduleScreen(draft: d),
        ),
      );
      await settle(tester);

      expect(d.hour, 8, reason: 'earliest open hour is preselected');
      expect(fake.lastCall('GET', '/slots')!.query['quote'], 'false');
      await _tap(tester, find.text(koT.dfSelect));
      expect(find.text(koT.dfSlotClosed), findsOneWidget);
      await tester.tap(find.text(slotRangeLabel(13, 'ko')).last);
      await settle(tester);
      await tester.tap(find.text(slotRangeLabel(14, 'ko')).last);
      await settle(tester);
      await _tap(tester, find.text(koT.dfSelectDone));
      expect(d.hour, 14, reason: 'the full 13:00 slot could not be chosen');
      expect(find.text(slotRangeLabel(14, 'ko')), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'when every arrival slot is full no hour is chosen and next is disabled',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 8)]);
      _openSlots(fake, available: false);
      final env = await TestEnv.create(fake: fake);
      final app = await _loaded(env);
      final d = BookingDraft(app.service('kitchen')!)
        ..address = app.addresses.first;
      await tester.pumpWidget(
        CustomerTestHost(
          env: env,
          app: app,
          home: ScheduleScreen(draft: d),
        ),
      );
      await settle(tester);

      expect(find.text(koT.scheduleFull), findsOneWidget);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      await unmount(tester);
    },
  );

  testWidgets('prep tools lists the 7 tools and "도구가 없으신가요?" opens the chat', (
    tester,
  ) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('POST', '/chat/threads', {'id': 'th-1'})
      ..reply('GET', '/chat/threads/th-1/messages', const <Json>[])
      ..reply('POST', '/chat/threads/th-1/read', null);
    stockCustomerApi(fake, name: '홍길동');
    final env = await TestEnv.create(fake: fake);
    final app = await _loaded(env);
    final d = BookingDraft(app.service('studio')!);
    await tester.pumpWidget(
      CustomerTestHost(
        env: env,
        app: app,
        home: PrepToolsScreen(draft: d),
      ),
    );
    await settle(tester);

    expect(find.text(koT.dfPrepHeader('홍길동')), findsOneWidget);
    for (final tool in prepTools) {
      expect(find.text(koT.tool(tool)), findsOneWidget);
    }
    await _tap(tester, find.text(koT.dfNoTools));
    expect(fake.lastCall('POST', '/chat/threads')!.json['topic'], 'studio');
    await unmount(tester);
  });

  testWidgets(
    'checkout pre-applies the best coupon and pays with the saved card in one POST',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()
        ..reply(
          'POST',
          '/bookings',
          bookingJson(id: 'bk-new', serviceCode: 'studio'),
        );
      stockCustomerApi(
        fake,
        addresses: [addressJson(sizePyeong: 8)],
        coupons: [
          couponJson(id: 'cp-any', name: 'any', amount: 5000),
          couponJson(
            id: 'cp-studio',
            name: 'studio',
            amount: 10000,
            serviceCode: 'studio',
          ),
        ],
        methods: [paymentMethodJson(id: 'pm-1')],
      );
      _openSlots(fake);
      final env = await TestEnv.create(fake: fake);
      await pumpCustomerApp(tester, env);
      await _openFromHome(tester, 'studio');

      await _tap(tester, find.text(koT.dfBookNow));
      await _tap(
        tester,
        find.text(koT.next).last,
      ); // date: the earliest open hour is preselected
      expect(
        find.byType(PrepToolsScreen),
        findsOneWidget,
        reason: 'studio needs the customer\'s tools',
      );
      await _tap(tester, find.text(koT.next).last);
      expect(find.byType(CheckoutScreen), findsOneWidget);

      // 45,000 list price minus the 10,000 studio coupon (the bigger of the two).
      expect(find.text('−${formatWon(10000, 'ko')}'), findsWidgets);
      expect(find.text('신한 1234'), findsOneWidget, reason: 'saved card row');
      final payLabel = koT.payAmount(formatWon(35000, 'ko'));
      await _tap(tester, find.text(payLabel));

      final body = fake.lastCall('POST', '/bookings')!.json;
      final tomorrow = DateUtils.dateOnly(
        DateTime.now(),
      ).add(const Duration(days: 1));
      expect(body['service_code'], 'studio');
      expect(body['address_id'], 'addr-1');
      expect(body['coupon_id'], 'cp-studio');
      expect(body['payment_method_id'], 'pm-1');
      expect(body['start_hour'], 8);
      expect(body['unit_index'], isNull);
      expect(body['visit_date'], isoDay(tomorrow));
      expect(
        body.containsKey('answers'),
        isFalse,
        reason: 'fixed-price services send no quote answers',
      );
      expect(find.byType(DoneScreen), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'checkout shows the PG notice with terms and refund links above the pay button',
    (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()
        ..reply('GET', '/policy/cancellation', {
          'policy': {
            'min_fee': 0,
            'tiers': [
              {'min_days': 2, 'percent': 0},
              {'min_days': 0, 'percent': 50},
            ],
          },
        });
      stockCustomerApi(
        fake,
        addresses: [addressJson(sizePyeong: 8)],
        methods: [paymentMethodJson(id: 'pm-1')],
      );
      final env = await TestEnv.create(fake: fake);
      final app = await _loaded(env);
      final d = BookingDraft(app.service('studio')!)
        ..address = app.addresses.first
        ..date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 5))
        ..hour = 9;
      await tester.pumpWidget(
        CustomerTestHost(
          env: env,
          app: app,
          home: CheckoutScreen(draft: d),
        ),
      );
      await settle(tester);

      expect(find.text(koT.dfPayTitle), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(koT.dfPgNotice),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.widgetWithText(TextButton, koT.moreTerms), findsOneWidget);
      await _tap(tester, find.widgetWithText(TextButton, koT.dfRefundPolicy));
      expect(
        find.text(koT.cpTitle),
        findsWidgets,
        reason: 'refund link shows the live cancellation rules',
      );
      await unmount(tester);
    },
  );

  testWidgets(
    'done screen shows the big confirm check, the summary, and holds still with reduced motion',
    (tester) async {
      setViewport(tester, const Size(412, 915));
      final env = await TestEnv.create(fake: FakeApi());
      final app = AppState(env.api, FakeRealtime(env.api));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        CustomerTestHost(
          env: env,
          app: app,
          home: DoneScreen(
            booking: Booking.fromJson(
              bookingJson(status: 1, paidAmount: 35000, address: addressJson()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<SuccessMark>(find.byType(SuccessMark)).size, 160);
      expect(find.text(formatWon(35000, 'ko')), findsOneWidget);
      expect(find.text(koT.goHome), findsOneWidget);
      expect(find.text(koT.viewBooking), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await unmount(tester);
    },
  );

  testWidgets(
    'service scope: chips switch the service, tabs and the floor plan switch the area',
    (tester) async {
      setViewport(tester, phoneSize);
      final env = await TestEnv.create(fake: FakeApi());
      await pumpCustomerScreen(tester, env, const ServiceScopeScreen());
      await settle(tester);

      expect(
        find.text(scopeLabel(koT, 'bedding')),
        findsOneWidget,
        reason: 'studio / room first',
      );
      await _tap(tester, find.text(koT.dfEntranceTrash));
      expect(find.text(scopeLabel(koT, 'trash')), findsOneWidget);
      await _tap(tester, find.text(koT.dfScopeMove));
      expect(
        find.text(scopeLabel(koT, 'windows')),
        findsOneWidget,
        reason: 'move scope starts at the room',
      );
      await _tap(tester, find.bySemanticsLabel(koT.dfKitchen).first);
      expect(
        find.text(scopeLabel(koT, 'hood')),
        findsOneWidget,
        reason: 'tapping the plan selects the kitchen',
      );
      expect(find.text(koT.dfNotProvided), findsOneWidget);
      await unmount(tester);
    },
  );
}
