import 'dart:async';

import 'package:core/core.dart';
import 'package:customer/screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Future<FakeApi> _chatApi(List<Json> history) async {
  final fake = FakeApi()
    ..reply('GET', '/chat/threads/th-1/messages', history)
    ..reply('POST', '/chat/threads/th-1/read', null)
    ..onPost('/chat/threads/th-1/messages', (call) => chatMessageJson(
          id: 'm-new',
          sender: 'customer',
          kind: 'text',
          body: {'text': call.json['text']},
        ));
  stockCustomerApi(fake);
  return fake;
}

void main() {
  testWidgets('system, request-card and quote bubbles render their own layouts', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([
      chatMessageJson(
        id: 'm1',
        sender: 'system',
        kind: 'system',
        body: {'code': 'deposit_paid', 'params': {'amount': 36000}},
      ),
      chatMessageJson(id: 'm2', sender: 'staff', kind: 'text', body: {'text': '방문 일정 확인했어요'}),
      chatMessageJson(
        id: 'm3',
        sender: 'staff',
        kind: 'card',
        body: {'service_code': 'studio', 'visit_date': '2026-12-01', 'estimate': 45000},
      ),
      chatMessageJson(
        id: 'm4',
        sender: 'staff',
        kind: 'quote',
        body: {'booking_id': 'bk-9', 'final_price': 120000, 'deposit': 36000, 'balance': 84000, 'note': ''},
      ),
    ]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'studio'));
    await pumpUntilFound(tester, find.text('방문 일정 확인했어요'));

    expect(find.text(koT.system('deposit_paid', {'amount': 36000}, 'ko')), findsOneWidget, reason: 'system pill');
    expect(find.text(koT.requestCard), findsOneWidget, reason: 'request card tag');
    expect(find.text(koT.service('studio')), findsWidgets);
    expect(find.text(koT.quoteArrived), findsOneWidget, reason: 'quote card header');
    expect(find.text(formatWon(120000, 'ko')), findsOneWidget, reason: 'quote card final price');
    // A deposit_paid system message in the thread flips the quote card to its paid state.
    expect(find.text(koT.quotePaid), findsOneWidget, reason: 'deposit already paid in this thread');
    expect(find.text(koT.quotePay), findsNothing);
    await unmount(tester);
  });

  testWidgets('a quick reply sends its text as a text message and clears nothing else', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'studio'));
    await pumpUntilFound(tester, find.text(koT.quick_hello));

    await tester.tap(find.widgetWithText(ActionChip, koT.quick_hello));
    await settle(tester);

    final sent = fake.lastCall('POST', '/chat/threads/th-1/messages')!.json;
    expect(sent, {'kind': 'text', 'text': koT.quick_hello});
    expect(find.text(koT.quick_hello), findsWidgets, reason: 'chip plus the echoed bubble');
    await unmount(tester);
  });

  testWidgets('the quote thread offers the three booking quick replies', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_in'));
    await pumpUntilFound(tester, find.text(koT.quick_confirm));

    for (final q in [koT.quick_confirm, koT.quick_quote, koT.quick_reschedule]) {
      expect(find.widgetWithText(ActionChip, q), findsOneWidget, reason: q);
    }
    expect(find.byType(ActionChip), findsNWidgets(3));
    expect(find.widgetWithText(ActionChip, koT.quick_hello), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, koT.quick_reschedule));
    await settle(tester);
    expect(fake.lastCall('POST', '/chat/threads/th-1/messages')!.json, {'kind': 'text', 'text': koT.quick_reschedule});
    await unmount(tester);
  });

  Json quote({String id = 'q1', int finalPrice = 350000, int deposit = 35000, bool structured = true}) => chatMessageJson(
        id: id,
        sender: 'staff',
        kind: 'quote',
        body: {
          'booking_id': 'bk-9',
          'final_price': finalPrice,
          'deposit': deposit,
          'balance': finalPrice - deposit,
          'note': null,
          if (structured) ...{
            'service_code': 'move_out',
            'visit_date': '2026-11-19',
            'start_hour': 8,
            'estimate': 346500,
            'answers': {'building': 'apartment', 'layout': 'two_rooms', 'bathrooms': 1},
          },
        },
      );

  testWidgets('the quote card shows every row from the message body', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote()]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    await pumpUntilFound(tester, find.text(koT.quoteArrived));

    expect(find.text('${dateLabel(DateTime(2026, 11, 19), 'ko')} ${koT.morning}'), findsOneWidget, reason: 'visit date + AM');
    expect(find.text(koT.service('move_out')), findsWidgets, reason: 'type');
    expect(find.text('${koT.building_apartment} · ${koT.layout_two_rooms}'), findsOneWidget, reason: 'structure');
    expect(find.text(formatWon(346500, 'ko')), findsOneWidget, reason: 'estimate');
    expect(find.text(formatWon(350000, 'ko')), findsOneWidget, reason: 'confirmed total');
    expect(find.text(formatWon(315000, 'ko')), findsOneWidget, reason: 'balance');
    expect(find.text(koT.quotePayAmount(formatWon(35000, 'ko'))), findsOneWidget, reason: 'deposit button');
    await unmount(tester);
  });

  testWidgets('a legacy quote body without the booking rows still renders and pays', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote(finalPrice: 120000, deposit: 12000, structured: false)]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_in'));
    await pumpUntilFound(tester, find.text(koT.quoteArrived));

    expect(find.text(formatWon(120000, 'ko')), findsOneWidget);
    expect(find.text(koT.quoteVisit), findsNothing);
    expect(find.text(koT.layoutTitle), findsNothing);
    expect(find.text(koT.quotePayAmount(formatWon(12000, 'ko'))), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('paying the deposit posts once with an idempotency key and flips the card to paid', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote()]);
    fake.onPost('/bookings/bk-9/deposit', (_) => bookingJson(id: 'bk-9', status: 1));
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    unawaited(app.loadMethods());
    final pay = find.text(koT.quotePayAmount(formatWon(35000, 'ko')));
    await pumpUntilFound(tester, pay);

    await tester.tap(pay);
    await settle(tester);
    await tester.tap(find.text('신한 1234'));
    await settle(tester);

    final calls = fake.callsTo('POST', '/bookings/bk-9/deposit');
    expect(calls, hasLength(1));
    expect(calls.single.json, {'payment_method_id': 'pm-1'}, reason: 'no amount from the client');
    expect(calls.single.headers.keys.map((k) => k.toLowerCase()), contains('idempotency-key'));
    expect(find.text(koT.quotePaid), findsOneWidget);
    expect(pay, findsNothing);
    await unmount(tester);
  });

  testWidgets('only the newest quote can be paid', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote(id: 'q-old', finalPrice: 300000, deposit: 30000), quote(id: 'q-new')]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    await pumpUntilFound(tester, find.text(koT.quoteSuperseded));

    expect(find.text(koT.quoteSuperseded), findsOneWidget);
    expect(find.text(koT.quotePayAmount(formatWon(35000, 'ko'))), findsOneWidget);
    expect(find.text(koT.quotePayAmount(formatWon(30000, 'ko'))), findsNothing);
    await unmount(tester);
  });

  testWidgets('chat list shows the team, the console operating hours and the reply-time line', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('GET', '/brand', {'support_hours': '평일 10:00-19:00 (예시)'});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatListTab());
    await pumpUntilFound(tester, find.text('${koT.chatHoursTitle} · 평일 10:00-19:00 (예시)'));

    expect(find.text(koT.chatReplyFast), findsWidgets);
    expect(find.text(koT.chatNew), findsOneWidget, reason: '+ new consultation');
    expect(find.text(koT.chatHours), findsNothing, reason: 'the setting replaces the built-in hours');
    await unmount(tester);
  });

  testWidgets('chat list falls back to the built-in hours when the setting is missing', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatListTab());
    await pumpUntilFound(tester, find.text('${koT.chatHoursTitle} · ${koT.chatHours}'));
    await unmount(tester);
  });
}
