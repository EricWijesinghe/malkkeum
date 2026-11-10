import 'dart:async';

import 'package:console/screens/bookings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';

const _row = 'B-20260101-0001';

void main() {
  testWidgets('wide layout: picking a booking opens its panel beside the list', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/bookings', [bookingJson(id: 'bk-1', number: _row, status: 2)])
      ..onGet('/admin/bookings/bk-1', (_) => bookingDetail(status: 2));
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const BookingsScreen());
    await pumpUntilFound(tester, find.text('$_row · ${koT.serviceShort('studio')}'));

    expect(find.text(koT.cSelectBooking), findsOneWidget, reason: 'nothing picked yet');
    await tester.tap(find.text('$_row · ${koT.serviceShort('studio')}'));
    await settle(tester);

    expect(find.text(koT.cSelectBooking), findsNothing);
    expect(find.text(koT.cChangeStatus), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('status change is busy-guarded: a second tap while saving sends nothing', (tester) async {
    setViewport(tester, wideSize);
    final gate = Completer<Object?>();
    final fake = FakeApi()
      ..reply('GET', '/admin/bookings', [bookingJson(id: 'bk-1', number: _row, status: 2)])
      ..onGet('/admin/bookings/bk-1', (_) => bookingDetail(status: 2))
      ..onPost('/admin/bookings/bk-1/status', (_) => gate.future);
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const BookingsScreen());
    await pumpUntilFound(tester, find.text('$_row · ${koT.serviceShort('studio')}'));
    await tester.tap(find.text('$_row · ${koT.serviceShort('studio')}'));
    await settle(tester);

    final markDone = find.widgetWithText(FilledButton, koT.cMarkDone);
    await tester.tap(markDone);
    await tester.pump();
    expect(tester.widget<FilledButton>(markDone).onPressed, isNull, reason: 'disabled while the request is in flight');
    await tester.tap(markDone, warnIfMissed: false);
    await settle(tester);
    expect(fake.callsTo('POST', '/admin/bookings/bk-1/status'), hasLength(1));

    gate.complete({'ok': true});
    await settle(tester);
    expect(fake.lastCall('POST', '/admin/bookings/bk-1/status')!.json, {'status': 3});
    await unmount(tester);
  });

  testWidgets('quote desk sends the chosen pro quote with its id and the typed price', (tester) async {
    setViewport(tester, wideSize);
    final quoteBooking = bookingJson(
      id: 'bk-1',
      number: _row,
      serviceCode: 'move_out',
      status: 0,
      estimate: 58000,
      answers: {'cleaning_type': 'standard', 'luggage': 'empty'},
    );
    final fake = FakeApi()
      ..reply('GET', '/admin/bookings', [quoteBooking])
      ..onGet('/admin/bookings/bk-1', (_) => bookingDetail(status: 0, answers: {'cleaning_type': 'standard'}, estimate: {'base': 50000, 'extras': 0, 'surcharge_bps': 0, 'before_vat': 50000, 'total': 55000}))
      ..reply('GET', '/admin/bookings/bk-1/quotes', [
        {'id': 'q-1', 'team_name': '팀A', 'pro_name': '김파트너', 'rating': 4.8, 'note': '', 'state': 'waiting', 'amount': 60000},
      ])
      ..reply('POST', '/admin/bookings/bk-1/send-quote', {'ok': true});
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const BookingsScreen(quoteDesk: true));
    await pumpUntilFound(tester, find.text('$_row · ${koT.serviceShort('move_out')}'));
    await tester.tap(find.text('$_row · ${koT.serviceShort('move_out')}'));
    await settle(tester);

    await tester.tap(find.text('팀A · 김파트너'));
    await settle(tester);
    expect(tester.widget<TextField>(find.widgetWithText(TextField, koT.cFinalPrice)).controller!.text, '60000');

    await tester.tap(find.widgetWithText(PrimaryButton, koT.cSendQuote));
    await settle(tester);
    expect(
      fake.lastCall('POST', '/admin/bookings/bk-1/send-quote')!.json,
      {'final_price': 60000, 'quote_id': 'q-1', 'note': null},
    );
    await unmount(tester);
  });
}
