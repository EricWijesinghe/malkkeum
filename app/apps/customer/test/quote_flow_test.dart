import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/quote_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Covered routes keep their widgets in the tree, so "Next" is ambiguous. The topmost
/// route is the last match in tree order.
Finder _topNext() => find.text(koT.next).last;

void main() {
  testWidgets('move-out quote: six steps, then the answers go to the server with enum names', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('POST', '/quote/estimate', {'total': 250000})
      ..reply('POST', '/bookings', bookingJson(id: 'bk-quote', serviceCode: 'move_out', status: 0));
    stockCustomerApi(fake, addresses: [addressJson(sizePyeong: 30)]);
    fake.reply('GET', '/slots', [slotJson(8), slotJson(13)]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);

    await pumpUntilFound(tester, find.text(koT.dhSvcMoveShort));
    await tester.tap(find.text(koT.dhSvcMoveShort));
    await settle(tester);
    await tester.tap(find.text(koT.service('move_out'))); // the sheet starts the questionnaire
    await settle(tester);
    expect(find.byType(QuoteFlowScreen), findsOneWidget);
    expect(find.text(koT.stepOf('1', '6')), findsOneWidget);

    // Step 1: cleaning type and luggage.
    await tester.tap(find.text(koT.type_standard));
    await settle(tester);
    await tester.tap(_topNext());
    await settle(tester);
    expect(find.text(koT.stepOf('2', '6')), findsOneWidget);

    // Step 2: building, layout, duplex. Step 3's yes/no is also in the tree, so take the first.
    await tester.tap(find.text(koT.building_apartment));
    await tester.tap(find.text(koT.layout_two_rooms));
    await settle(tester);
    await tester.tap(find.text(koT.yes).first);
    await settle(tester);
    await tester.tap(_topNext());
    await settle(tester);
    expect(find.text(koT.stepOf('3', '6')), findsOneWidget);

    // Step 3: elevator, the last yes/no in tree order while this page is visible.
    await tester.tap(find.text(koT.yes).last);
    await settle(tester);
    await tester.tap(_topNext());
    await settle(tester);

    // Step 4 (address, preselected) -> step 5 (schedule) -> step 6 (estimate and confirm).
    expect(find.text(koT.stepOf('4', '6')), findsOneWidget);
    await tester.tap(_topNext());
    await settle(tester);
    expect(find.text(koT.stepOf('5', '6')), findsOneWidget);
    await tester.tap(_topNext());
    await settle(tester);
    expect(find.byType(QuoteConfirmScreen), findsOneWidget);

    await tester.tap(find.text(koT.quoteRequest));
    await settle(tester, duration: const Duration(seconds: 1));

    final body = fake.lastCall('POST', '/bookings')!.json;
    expect(body['service_code'], 'move_out');
    expect(body['start_hour'], 8, reason: 'morning slot is preselected');
    final answers = body['answers'] as Map<String, dynamic>;
    expect(answers['cleaning_type'], 'standard');
    expect(answers['luggage'], 'empty');
    expect(answers['building'], 'apartment');
    expect(answers['layout'], 'two_rooms');
    expect(answers['duplex'], isTrue);
    expect(answers['bathrooms'], 1);
    expect(answers['balconies'], 0);
    expect(answers['elevator'], isTrue);
    expect(answers['floor_3_or_higher'], isFalse);
    expect(find.byType(DoneScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the first quote step cannot advance until the cleaning type is chosen', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);

    await pumpUntilFound(tester, find.text(koT.dhSvcMoveShort));
    await tester.tap(find.text(koT.dhSvcMoveShort));
    await settle(tester);
    await tester.tap(find.text(koT.service('move_in')));
    await settle(tester);

    final next = find.widgetWithText(PrimaryButton, koT.next).last;
    expect(tester.widget<PrimaryButton>(next).onPressed, isNull);
    await tester.tap(find.text(koT.type_normal_move_in));
    await settle(tester);
    expect(tester.widget<PrimaryButton>(next).onPressed, isNotNull);
    await unmount(tester);
  });
}
