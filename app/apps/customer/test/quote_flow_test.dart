import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/chat.dart';
import 'package:customer/screens/quote_flow.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Covered routes keep their widgets in the tree, so "Next" is ambiguous. The topmost
/// route is the last match in tree order.
Finder _topNext() => find.text(koT.next).last;

/// Tiles can sit below the fold on a phone: scroll them in before tapping.
Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

/// The server's itemised estimate; the screen only renders it.
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
};

Future<FakeApi> _pumpMoveOut(WidgetTester tester) async {
  setViewport(tester, phoneSize);
  final fake = FakeApi()
    ..reply('POST', '/quote/estimate', _estimate)
    ..reply('POST', '/bookings', bookingJson(id: 'bk-quote', serviceCode: 'move_out', status: 0, threadId: 'th-1'))
    ..reply('GET', '/chat/threads/th-1/messages', const <Json>[])
    ..reply('POST', '/chat/threads/th-1/read', null);
  stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 30)]);
  fake.reply('GET', '/slots', [slotJson(8), slotJson(13)]);
  final env = await TestEnv.create(fake: fake);
  final app = await pumpCustomerScreen(tester, env, QuoteFlowScreen(service: Service.fromJson(serviceJson('move_out'))));
  await app.loadAll();
  await settle(tester);
  return fake;
}

void main() {
  testWidgets('move-out quote: five steps, AC add-on, Safe booking review, then the booking chat opens', (tester) async {
    final fake = await _pumpMoveOut(tester);
    expect(find.text(koT.stepOf('1', '5')), findsOneWidget);

    // Step 1: cleaning type and the condition boxes (3 tiles, "not sure" stays a chip).
    expect(find.byType(ChoiceTile3D), findsNWidgets(3));
    await _tap(tester, find.text(koT.type_standard));
    await _tap(tester, find.text(koT.luggage_partly_unpacked));
    await settle(tester);
    await tester.tap(_topNext());
    await settle(tester);
    expect(find.text(koT.stepOf('2', '5')), findsOneWidget);

    // Step 2: Apartment / Villa / Commercial + "기타", structure tiles, duplex.
    expect(find.text(koT.building_commercial), findsOneWidget);
    expect(find.text(koT.building_officetel), findsNothing, reason: 'other buildings sit under 기타');
    await _tap(tester, find.text(koT.building_other));
    await settle(tester);
    expect(find.text(koT.building_officetel), findsOneWidget);
    await _tap(tester, find.text(koT.building_commercial));
    await _tap(tester, find.text(koT.layout_two_rooms));
    await settle(tester);
    await _tap(tester, find.text(koT.yes).first);
    await settle(tester);
    await tester.tap(_topNext());
    await settle(tester);
    expect(find.text(koT.stepOf('3', '5')), findsOneWidget);

    // Step 3: counts 0-5 and the elevator tiles (the last yes/no in tree order).
    await _tap(tester, find.text(koT.no).last);
    await settle(tester);
    await tester.tap(_topNext());
    await settle(tester);

    // Step 4: date + AM/PM (address preselected), and the AC add-on banner with catalog prices.
    expect(find.byType(ScheduleScreen), findsOneWidget);
    expect(find.text(koT.stepOf('4', '5')), findsOneWidget);
    expect(find.text(koT.morning), findsOneWidget);
    await _tap(tester, find.text(koT.dfAcAddonAdd));
    await settle(tester);
    final wall = find.widgetWithText(CountStepper, '${koT.unit('wall')} · ${formatWon(79000, 'ko')}');
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(wall, findsOneWidget, reason: 'price comes from the catalog');
    await _tap(tester, find.descendant(of: wall, matching: find.byTooltip('+')));
    await settle(tester);
    Navigator.of(tester.element(wall)).pop();
    await settle(tester);
    expect(find.text(koT.dfAcAddonAdded('1')), findsOneWidget);
    await tester.tap(_topNext());
    await settle(tester);

    // Step 5: "안심 예약" with the server's itemised lines.
    expect(find.byType(QuoteConfirmScreen), findsOneWidget);
    expect(find.text(koT.stepOf('5', '5')), findsOneWidget);
    expect(find.text(koT.dfSafeBooking), findsOneWidget);
    expect(find.text(koT.dfEstAddons('10')), findsOneWidget);
    expect(find.text('+${formatWon(71100, 'ko')}'), findsOneWidget);
    final estimateCall = fake.lastCall('POST', '/quote/estimate')!.json;
    expect(estimateCall['ac_addons'], [
      {'unit': 'wall', 'count': 1},
    ]);

    await _tap(tester, find.text(koT.quoteRequest));
    await settle(tester, duration: const Duration(seconds: 1));

    final body = fake.lastCall('POST', '/bookings')!.json;
    expect(body['service_code'], 'move_out');
    expect(body['start_hour'], 8, reason: 'morning slot is preselected');
    final answers = body['answers'] as Map<String, dynamic>;
    expect(answers['cleaning_type'], 'standard');
    expect(answers['luggage'], 'partly_unpacked');
    expect(answers['building'], 'commercial');
    expect(answers['layout'], 'two_rooms');
    expect(answers['duplex'], isTrue);
    expect(answers['bathrooms'], 1);
    expect(answers['balconies'], 0);
    expect(answers['elevator'], isFalse);
    expect(answers['floor_3_or_higher'], isFalse);
    expect(answers['ac_addons'], [
      {'unit': 'wall', 'count': 1},
    ]);
    // Submit opens the booking chat for the final confirmation.
    expect(find.byType(ChatRoomScreen), findsOneWidget);
    expect(tester.widget<ChatRoomScreen>(find.byType(ChatRoomScreen)).bookingId, 'bk-quote');
    expect(find.byType(DoneScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('the first quote step cannot advance until the cleaning type is chosen', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, QuoteFlowScreen(service: Service.fromJson(serviceJson('move_in'))));
    await settle(tester);

    final next = find.widgetWithText(PrimaryButton, koT.next).last;
    expect(tester.widget<PrimaryButton>(next).onPressed, isNull);
    await _tap(tester, find.text(koT.type_normal_move_in));
    await settle(tester);
    expect(tester.widget<PrimaryButton>(next).onPressed, isNotNull);
    await unmount(tester);
  });

  testWidgets('without add-ons the estimate shows no AC line and no answers key is invented', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('POST', '/quote/estimate', {..._estimate, 'addons': 0, 'addon_discount_bps': 0, 'total': 330000});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    final d = BookingDraft(Service.fromJson(serviceJson('move_in')))
      ..address = Address.fromJson(addressJson())
      ..date = DateTime(2030, 1, 2)
      ..hour = 13
      ..answers.cleaningType = 'normal_move_in'
      ..answers.building = 'apartment'
      ..answers.layout = 'two_rooms'
      ..answers.duplex = false
      ..answers.elevator = true;
    await pumpCustomerScreen(tester, env, QuoteConfirmScreen(draft: d));
    await settle(tester);
    expect(find.textContaining(koT.dfEstAddons('10')), findsNothing);
    expect(find.text(formatWon(330000, 'ko')), findsWidgets);
    expect(fake.lastCall('POST', '/quote/estimate')!.json['ac_addons'], isEmpty);
    await unmount(tester);
  });
}
