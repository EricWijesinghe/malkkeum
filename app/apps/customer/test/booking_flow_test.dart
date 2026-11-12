import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/service.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// From the home grid, open a service's detail screen.
Future<void> _openFromHome(WidgetTester tester, String code) async {
  await pumpUntilFound(tester, find.text(koT.serviceShort(code)));
  await tester.tap(find.text(koT.serviceShort(code)));
  await settle(tester);
}

/// Every slot the schedule asks for is open, unless a test overrides it.
void _openSlots(FakeApi fake, {bool available = true}) {
  fake.reply('GET', '/slots', [for (final h in const [8, 9, 13, 14]) slotJson(h, available: available)]);
}

void main() {
  testWidgets('bathroom unit choice updates the rolling price on the service screen', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);
    await _openFromHome(tester, 'bathroom');

    Finder amount(int won) => find.descendant(of: find.byType(RollingAmount), matching: find.text(formatWon(won, 'ko')));
    expect(amount(39000), findsOneWidget, reason: 'first unit is preselected');

    await tester.tap(find.text(koT.unit('count_3')));
    await settle(tester, duration: const Duration(milliseconds: 800));
    expect(amount(69000), findsOneWidget);
    expect(amount(39000), findsNothing);
    await unmount(tester);
  });

  testWidgets('one saved address that fits the service skips straight to the schedule (step 2 of 3)', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    // 8 pyeong is under the studio limit of 10, so the address step is skipped.
    stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 8)]);
    _openSlots(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);
    await _openFromHome(tester, 'studio');

    await tester.tap(find.text(koT.chooseDate));
    await settle(tester);
    expect(find.text(koT.stepOf('2', '3')), findsOneWidget);
    expect(find.byType(AddressPickScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('a studio too big for the only saved address goes to the address step instead', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 25)]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);
    await _openFromHome(tester, 'studio');

    await tester.tap(find.text(koT.chooseDate));
    await settle(tester);
    expect(find.byType(AddressPickScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('when every arrival slot is full they are all disabled and no hour is chosen', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    _openSlots(fake, available: false);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);
    await _openFromHome(tester, 'kitchen');

    await tester.tap(find.text(koT.chooseDate));
    await settle(tester);
    expect(find.text(koT.scheduleFull), findsNWidgets(4));
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed, isNull, reason: 'payment needs an hour');

    final slotCall = fake.lastCall('GET', '/slots')!;
    expect(slotCall.query['quote'], 'false');
    expect(slotCall.query['date'], isNotNull);
    await unmount(tester);
  });

  testWidgets('checkout pre-applies the best coupon and pays with the saved card in one POST', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('POST', '/bookings', bookingJson(id: 'bk-new', serviceCode: 'studio'));
    stockCustomerApi(
      fake,
      addresses: [addressJson(sizePyeong: 8)],
      coupons: [
        couponJson(id: 'cp-any', name: 'any', amount: 5000),
        couponJson(id: 'cp-studio', name: 'studio', amount: 10000, serviceCode: 'studio'),
      ],
      methods: [paymentMethodJson(id: 'pm-1')],
    );
    _openSlots(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);
    await _openFromHome(tester, 'studio');

    await tester.tap(find.text(koT.chooseDate));
    await settle(tester);
    // The earliest open hour is preselected, so the payment step is reachable directly.
    await tester.tap(find.text(koT.goToPayment));
    await settle(tester);
    expect(find.byType(CheckoutScreen), findsOneWidget);

    // 45,000 list price minus the 10,000 studio coupon (the bigger of the two).
    final payLabel = koT.payAmount(formatWon(35000, 'ko'));
    expect(find.text(payLabel), findsOneWidget);
    await tester.tap(find.text(payLabel));
    await settle(tester, duration: const Duration(seconds: 1));

    final body = fake.lastCall('POST', '/bookings')!.json;
    final tomorrow = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    expect(body['service_code'], 'studio');
    expect(body['address_id'], 'addr-1');
    expect(body['coupon_id'], 'cp-studio');
    expect(body['payment_method_id'], 'pm-1');
    expect(body['start_hour'], 8);
    expect(body['unit_index'], isNull);
    expect(body['visit_date'], isoDay(tomorrow));
    expect(body.containsKey('answers'), isFalse, reason: 'fixed-price services send no quote answers');
    expect(find.byType(DoneScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('studio info comes from the catalog and the blueprint lists the 5 scope items', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    // A console-edited price: the screen must show it, not a built-in number.
    final studio = serviceJson('studio')..['pricing'] = {'type': 'fixed', 'price': 51000, 'minutes': 120};
    await pumpCustomerScreen(tester, env, ServiceScreen(service: Service.fromJson(studio)));
    await settle(tester);

    expect(find.text(koT.duration(120)), findsOneWidget);
    expect(find.text(formatWon(51000, 'ko')), findsWidgets);
    expect(find.text(koT.vatIncluded), findsOneWidget);
    expect(find.byType(ScopeBlueprint), findsOneWidget);
    for (final label in [koT.dfScopeDusting, koT.dfScopeVacuum, koT.dfScopeDishes, koT.dfScopeBathroom, koT.dfScopeTrash]) {
      expect(find.descendant(of: find.byType(ScopeBlueprint), matching: find.text(label)), findsOneWidget);
    }
    await unmount(tester);
  });

  testWidgets('AC shows four 3D unit tiles priced from the catalog', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    final ac = Service.fromJson(serviceJson('aircon'));
    await pumpCustomerScreen(tester, env, ServiceScreen(service: ac));
    await settle(tester);

    expect(find.byType(ChoiceTile3D), findsNWidgets(4));
    for (final u in ac.units) {
      expect(find.widgetWithText(ChoiceTile3D, formatWon(u.price, 'ko')), findsOneWidget);
    }
    await tester.tap(find.text(koT.unit('two_in_one')));
    await settle(tester, duration: const Duration(milliseconds: 800));
    expect(find.descendant(of: find.byType(RollingAmount), matching: find.text(formatWon(ac.units[2].price, 'ko'))), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('address step preselects a saved address that fits and labels the one over 10 pyeong', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, addresses: [
      addressJson(id: 'a-big', label: '부모님댁', sizePyeong: 24),
      addressJson(id: 'a-home', label: '우리집', sizePyeong: 9),
    ]);
    final env = await TestEnv.create(fake: fake);
    final app = AppState(env.api, FakeRealtime(env.api));
    await app.loadAll();
    final d = BookingDraft(Service.fromJson(serviceJson('studio')));
    await tester.pumpWidget(CustomerTestHost(env: env, app: app, home: AddressPickScreen(draft: d)));
    await settle(tester);

    expect(d.address?.id, 'a-home');
    expect(find.text(koT.dfOverPyeong('10')), findsOneWidget);
    expect(find.text(koT.addressAdd), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('checkout has the 3D tool checklist and the PG notice with terms and refund links', (tester) async {
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
    stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 8)], methods: [paymentMethodJson(id: 'pm-1')]);
    final env = await TestEnv.create(fake: fake);
    final app = AppState(env.api, FakeRealtime(env.api));
    await app.loadAll();
    final d = BookingDraft(app.service('studio')!)
      ..address = app.addresses.first
      ..date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 5))
      ..hour = 9;
    await tester.pumpWidget(CustomerTestHost(env: env, app: app, home: CheckoutScreen(draft: d)));
    await settle(tester);

    final checklist = find.byType(PrepChecklist);
    await tester.scrollUntilVisible(checklist, 200, scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: checklist, matching: find.byType(ChoiceTile3D)), findsNWidgets(prepTools.length));
    expect(find.text(koT.dfPrepCount('0', '${prepTools.length}')), findsOneWidget);
    await tester.tap(find.descendant(of: checklist, matching: find.text(koT.tool('gloves'))));
    await settle(tester);
    expect(find.text(koT.dfPrepCount('1', '${prepTools.length}')), findsOneWidget);

    await tester.scrollUntilVisible(find.text(koT.dfPgNotice), 200, scrollable: find.byType(Scrollable).first);
    expect(find.widgetWithText(TextButton, koT.moreTerms), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, koT.dfRefundPolicy));
    await settle(tester);
    expect(find.text(koT.cpTitle), findsWidgets, reason: 'refund link shows the live cancellation rules');
    await unmount(tester);
  });

  testWidgets('done screen shows the big confirm check and holds still with reduced motion', (tester) async {
    setViewport(tester, const Size(412, 915));
    final env = await TestEnv.create(fake: FakeApi());
    final app = AppState(env.api, FakeRealtime(env.api));
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      CustomerTestHost(env: env, app: app, home: DoneScreen(booking: Booking.fromJson(bookingJson(status: 1, paidAmount: 45000)))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.widget<SuccessMark>(find.byType(SuccessMark)).size, 160);
    expect(tester.hasRunningAnimations, isFalse);
    await unmount(tester);
  });
}
