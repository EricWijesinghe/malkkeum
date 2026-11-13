import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:customer/screens/chat.dart';
import 'package:customer/state.dart';
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

/// A realtime double whose events the test sends itself.
class _LiveRealtime extends FakeRealtime {
  _LiveRealtime(super.api);
  final _sent = StreamController<Json>.broadcast();

  @override
  Stream<Json> get events => _sent.stream;

  void emit(Json event) => _sent.add(event);
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
    expect(find.text(koT.chatRequestTitle(koT.service('studio'))), findsOneWidget, reason: 'request card band');
    expect(find.text(koT.service('studio')), findsWidgets);
    expect(find.text(koT.quoteConfirmedTitle), findsOneWidget, reason: 'quote card label');
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

    // The chip row scrolls sideways (design p04): bring the third reply into view first.
    await tester.ensureVisible(find.widgetWithText(ActionChip, koT.quick_reschedule));
    await settle(tester);
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

  testWidgets('the request card shows the booking rows and the quote card the total and deposit from the body', (tester) async {
    setViewport(tester, phoneSize);
    final card = quote();
    card['id'] = 'c1';
    card['kind'] = 'card';
    final fake = await _chatApi([card, quote()]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    await pumpUntilFound(tester, find.text(koT.quoteConfirmedTitle));

    expect(find.text(koT.chatRequestTitle(koT.service('move_out'))), findsOneWidget, reason: 'request band');
    expect(find.text('${dateLabel(DateTime(2026, 11, 19), 'ko')} ${koT.morning}'), findsOneWidget, reason: 'visit date + AM');
    expect(find.text(koT.service('move_out')), findsWidgets, reason: 'type');
    expect(find.text('${koT.building_apartment} · ${koT.layout_two_rooms}'), findsOneWidget, reason: 'structure');
    expect(find.text(formatWon(346500, 'ko')), findsOneWidget, reason: 'estimate');
    expect(find.text(formatWon(350000, 'ko')), findsOneWidget, reason: 'confirmed total');
    expect(find.text(koT.quoteDepositLine('10', formatWon(35000, 'ko'))), findsOneWidget, reason: 'deposit sentence');
    expect(find.text(koT.quotePayDeposit), findsOneWidget, reason: 'deposit button');
    await unmount(tester);
  });

  testWidgets('a legacy quote body without the booking rows still renders and pays', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote(finalPrice: 120000, deposit: 12000, structured: false)]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_in'));
    await pumpUntilFound(tester, find.text(koT.quoteConfirmedTitle));

    expect(find.text(formatWon(120000, 'ko')), findsOneWidget);
    expect(find.text(koT.quoteVisit), findsNothing);
    expect(find.text(koT.layoutTitle), findsNothing);
    expect(find.text(koT.quoteDepositLine('10', formatWon(12000, 'ko'))), findsOneWidget);
    expect(find.text(koT.quotePayDeposit), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('paying the deposit posts once with an idempotency key and flips the card to paid', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote()]);
    fake.onPost('/bookings/bk-9/deposit', (_) => bookingJson(id: 'bk-9', status: 1));
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    unawaited(app.loadMethods());
    final pay = find.text(koT.quotePayDeposit);
    await pumpUntilFound(tester, pay);

    await tester.tap(pay);
    await settle(tester);
    await tester.tap(find.text('신한 1234'));
    await settle(tester);

    final calls = fake.callsTo('POST', '/bookings/bk-9/deposit');
    expect(calls, hasLength(1));
    expect(
      calls.single.json,
      {'payment_method_id': 'pm-1', 'expected_deposit': 35000, 'expected_final_price': 350000, 'expected_quote_message_id': 'q1'},
      reason: 'binds to the card the customer saw',
    );
    expect(calls.single.headers.keys.map((k) => k.toLowerCase()), contains('idempotency-key'));
    expect(find.text(koT.quotePaid), findsOneWidget);
    expect(pay, findsNothing);
    await unmount(tester);
  });

  Future<FakeApi> openAndPay(WidgetTester tester, FakeApi fake) async {
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    unawaited(app.loadMethods());
    await pumpUntilFound(tester, find.text(koT.quotePayDeposit));
    return fake;
  }

  Future<void> tapPay(WidgetTester tester) async {
    await tester.tap(find.text(koT.quotePayDeposit));
    await settle(tester);
    await tester.tap(find.text('신한 1234'));
    await settle(tester);
  }

  testWidgets('a quote changed since the card was shown: the room reloads and says so', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote()]);
    fake.onPost('/bookings/bk-9/deposit', (_) => const ApiReply(409, {'error': {'code': 'price_changed', 'current': 50000}}));
    await openAndPay(tester, fake);
    final loadsBefore = fake.callsTo('GET', '/chat/threads/th-1/messages').length;

    await tapPay(tester);

    expect(find.text(koT.error(const ApiException(409, 'price_changed'))), findsOneWidget, reason: 'toast');
    expect(fake.callsTo('GET', '/chat/threads/th-1/messages').length, greaterThan(loadsBefore), reason: 'messages reloaded');
    expect(find.text(koT.quotePaid), findsNothing);
    await unmount(tester);
  });

  testWidgets('a retry after a lost reply reuses the idempotency key; a refusal gets a fresh one', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote()]);
    final replies = [const ApiReply(503, {'error': {'code': 'unavailable'}}), const ApiReply(409, {'error': {'code': 'booking_changed'}})];
    fake.onPost('/bookings/bk-9/deposit', (_) => replies.isEmpty ? bookingJson(id: 'bk-9', status: 1) : replies.removeAt(0));
    await openAndPay(tester, fake);

    String key(ApiCall c) => c.headers.entries.firstWhere((h) => h.key.toLowerCase() == 'idempotency-key').value;
    await tapPay(tester);
    await tapPay(tester);
    await tapPay(tester);

    final calls = fake.callsTo('POST', '/bookings/bk-9/deposit');
    expect(calls, hasLength(3));
    expect(key(calls[1]), key(calls[0]), reason: '5xx: same attempt');
    expect(key(calls[2]), isNot(key(calls[1])), reason: '4xx ended that attempt');
    expect(find.text(koT.quotePaid), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a card without a numeric deposit is never paid: error and reload instead', (tester) async {
    setViewport(tester, phoneSize);
    final broken = quote();
    (broken['body'] as Json)['deposit'] = null;
    final fake = await _chatApi([broken]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    await pumpUntilFound(tester, find.text(koT.quoteConfirmedTitle));
    final loadsBefore = fake.callsTo('GET', '/chat/threads/th-1/messages').length;

    await tester.tap(find.byWidgetPredicate((w) => w is FilledButton && w.onPressed != null));
    await settle(tester);

    expect(find.text(koT.errorGeneric), findsOneWidget);
    expect(fake.callsTo('GET', '/chat/threads/th-1/messages').length, greaterThan(loadsBefore));
    expect(fake.callsTo('POST', '/bookings/bk-9/deposit'), isEmpty);
    expect(find.text(koT.apPayAllTitle), findsNothing, reason: 'no method picker');
    await unmount(tester);
  });

  testWidgets('only the newest quote can be paid', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote(id: 'q-old', finalPrice: 300000, deposit: 30000), quote(id: 'q-new')]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    await pumpUntilFound(tester, find.text(koT.quoteSuperseded));

    expect(find.text(koT.quoteSuperseded), findsOneWidget);
    expect(find.text(koT.quotePayDeposit), findsOneWidget);
    final payable = find.byWidgetPredicate((w) => w is FilledButton && w.onPressed != null);
    expect(payable, findsOneWidget);
    expect(find.descendant(of: payable, matching: find.text(koT.quotePayDeposit)), findsOneWidget, reason: 'the newest card is the payable one');
    await unmount(tester);
  });

  testWidgets('chat list shows the console operating hours and the reply-time line in one bar', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('GET', '/brand', {'support_hours': '평일 10:00-19:00 (예시)'});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatListTab());
    await pumpUntilFound(tester, find.text('${koT.chatHoursTitle} · 평일 10:00-19:00 (예시) · ${koT.chatReplyFast}'));

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
    await pumpUntilFound(tester, find.text('${koT.chatHoursTitle} · ${koT.chatHours} · ${koT.chatReplyFast}'));
    await unmount(tester);
  });

  testWidgets('the quote card is teal-bordered with an inset teal button, never yellow', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([quote()]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    await pumpUntilFound(tester, find.text(koT.quotePayDeposit));
    await settle(tester);

    final ctx = tester.element(find.text(koT.quotePayDeposit));
    final colors = ctx.colors;
    final card = find.byWidgetPredicate((w) {
      final d = w is Container ? w.decoration : null;
      return d is BoxDecoration && d.border is Border && (d.border! as Border).top.width == 1.5;
    });
    expect(card, findsOneWidget, reason: '1.5px teal border');
    final border = ((tester.widget<Container>(card).decoration! as BoxDecoration).border! as Border).top;
    expect(border.color, colors.fresh);
    final button = find.byType(FilledButton);
    final fill = tester.widget<Material>(find.descendant(of: button, matching: find.byType(Material)).first).color;
    expect(fill, BrandConfig.placeholder.primary, reason: 'teal fill (dark teal keeps white text AA)');
    expect(1.05 / (fill!.computeLuminance() + 0.05), greaterThanOrEqualTo(4.5), reason: 'white label contrast');
    expect(fill, isNot(colors.sun), reason: 'no yellow');
    expect(tester.getSize(button).width, lessThan(tester.getSize(card).width), reason: 'inset, not full-bleed');
    await unmount(tester);
  });

  testWidgets('a paid quote reads as done and a superseded one cannot be paid', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([
      quote(id: 'q-old', finalPrice: 300000, deposit: 30000),
      quote(id: 'q-new'),
      chatMessageJson(id: 's1', sender: 'system', kind: 'system', body: {'code': 'deposit_paid', 'params': {'amount': 35000}}),
    ]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
    await pumpUntilFound(tester, find.text(koT.quotePaid));
    await settle(tester);

    expect(find.byWidgetPredicate((w) => w is FilledButton && w.onPressed != null), findsNothing);
    expect(find.text(koT.quotePayDeposit), findsNothing);
    await unmount(tester);
  });

  testWidgets('each day gets a date pill and the received notice joins the first one', (tester) async {
    setViewport(tester, phoneSize);
    Json at(Json m, DateTime t) => m..['created_at'] = t.toUtc().toIso8601String();
    final day1 = DateTime(2026, 11, 12, 10);
    final day2 = DateTime(2026, 11, 13, 9);
    final fake = await _chatApi([
      at(chatMessageJson(id: 's0', sender: 'system', kind: 'system', body: {'code': 'consultation_received'}), day1),
      at(chatMessageJson(id: 'm1', kind: 'text', body: {'text': '첫날'}), day1),
      at(chatMessageJson(id: 'm2', kind: 'text', body: {'text': '다음날'}), day2),
    ]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_in'));
    await pumpUntilFound(tester, find.text('다음날'));

    expect(find.text('${dateLabel(day1, 'ko')} · ${koT.chatDayReceived}'), findsOneWidget);
    expect(find.text(dateLabel(day2, 'ko')), findsOneWidget);
    expect(find.text(koT.system('consultation_received', const {}, 'ko')), findsNothing, reason: 'folded into the date pill');
    await unmount(tester);
  });

  testWidgets('thread rows use the design titles, a relative time and the unread badge', (tester) async {
    setViewport(tester, phoneSize);
    final now = DateTime.now();
    Json thread(String id, String topic, DateTime at, int unread) => {
      'id': id,
      'topic': topic,
      'unread_member': unread,
      'unread_staff': 0,
      'last_message_at': at.toUtc().toIso8601String(),
      'last_message': {'kind': 'text', 'body': {'text': 'hi $id'}},
    };
    final fake = FakeApi()
      ..reply('GET', '/chat/threads', [
        thread('a', 'move_out', now, 1),
        thread('b', 'aircon', DateTime(now.year, now.month, now.day - 1, 12), 0),
      ]);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatListTab());
    await pumpUntilFound(tester, find.text('hi a'));
    await settle(tester);

    expect(find.text(koT.chatThreadConsult(koT.service('move_out'))), findsOneWidget);
    expect(find.text(koT.chatThreadAsk(koT.service('aircon'))), findsOneWidget);
    expect(find.text(timeLabel(now, 'ko')), findsOneWidget, reason: 'today: the time');
    expect(find.text(koT.chatYesterday), findsOneWidget);
    expect(find.widgetWithText(Badge, '1'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing, reason: 'new chat is a header pill');
    await unmount(tester);
  });

  testWidgets('with reduced motion a live message shows at once', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(
      tester,
      env,
      Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: true),
          child: const ChatRoomScreen(threadId: 'th-1', topic: 'studio'),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text(koT.quick_hello));
    await tester.tap(find.widgetWithText(ActionChip, koT.quick_hello));
    await tester.pump();
    await tester.pump();

    final fade = tester.widget<FadeTransition>(find.ancestor(of: find.text(koT.quick_hello).first, matching: find.byType(FadeTransition)).first);
    expect(fade.opacity.value, 1, reason: 'no entrance animation');
    await unmount(tester);
  });

  testWidgets('a failed first load shows the error state with retry, and the retry loads the room', (tester) async {
    setViewport(tester, phoneSize);
    var online = false;
    final fake = FakeApi()
      ..onGet('/chat/threads/th-1/messages', (_) {
        if (!online) throw const SocketException('no signal');
        return [chatMessageJson(id: 'm1', sender: 'staff', kind: 'text', body: {'text': '방문 일정 확인했어요'})];
      })
      ..reply('POST', '/chat/threads/th-1/read', null);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'studio'));
    await pumpUntilFound(tester, find.byType(ErrorRetry));

    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'no spinner forever');
    expect(find.text(koT.errorNetwork), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);

    online = true;
    await tester.tap(find.text(koT.retry));
    await pumpUntilFound(tester, find.text('방문 일정 확인했어요'));
    expect(find.byType(ErrorRetry), findsNothing);
    await unmount(tester);
  });

  testWidgets('a failed reload keeps the messages already in the room', (tester) async {
    setViewport(tester, phoneSize);
    var online = true;
    final fake = FakeApi()
      ..onGet('/chat/threads/th-1/messages', (_) {
        if (!online) throw const SocketException('no signal');
        return [chatMessageJson(id: 'm1', sender: 'staff', kind: 'text', body: {'text': '방문 일정 확인했어요'})];
      })
      ..reply('POST', '/chat/threads/th-1/read', null);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    final live = _LiveRealtime(env.api);
    await tester.pumpWidget(
      CustomerTestHost(env: env, app: AppState(env.api, live), home: const ChatRoomScreen(threadId: 'th-1', topic: 'studio')),
    );
    await pumpUntilFound(tester, find.text('방문 일정 확인했어요'));

    online = false;
    live.emit({'type': 'resync'});
    await settle(tester, duration: const Duration(milliseconds: 500));

    expect(find.text('방문 일정 확인했어요'), findsOneWidget);
    expect(find.byType(ErrorRetry), findsNothing);
    await settle(tester, duration: const Duration(seconds: 5)); // let the toast leave
    await unmount(tester);
  });
}
