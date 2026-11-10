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

  testWidgets('the quote thread offers the move-in quick replies instead of the general ones', (tester) async {
    setViewport(tester, phoneSize);
    final fake = await _chatApi([]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_in'));
    await pumpUntilFound(tester, find.text(koT.quick_confirm));

    expect(find.widgetWithText(ActionChip, koT.quick_confirm), findsOneWidget);
    // The fourth chip sits past the strip's edge; the horizontal ListView builds it only once scrolled into view.
    final strip = find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal);
    await tester.scrollUntilVisible(
      find.widgetWithText(ActionChip, koT.quick_parking),
      60,
      scrollable: find.descendant(of: strip, matching: find.byType(Scrollable)),
    );
    expect(find.widgetWithText(ActionChip, koT.quick_parking), findsOneWidget);
    expect(find.widgetWithText(ActionChip, koT.quick_hello), findsNothing);
    await unmount(tester);
  });
}
