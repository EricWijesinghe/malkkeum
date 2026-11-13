import 'package:core/core.dart';
import 'package:customer/screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Chat list header, the request card and the quote card on the smallest phone at large text, every locale.
const _smallPhone = Size(320, 568);

const Json _request = {
  'booking_id': 'bk-9',
  'service_code': 'move_out',
  'visit_date': '2026-11-19',
  'start_hour': 8,
  'estimate': 346500,
  'answers': {'building': 'officetel', 'layout': 'one_and_half'},
};

FakeApi _api() {
  final fake = FakeApi()
    ..reply('GET', '/brand', {'support_hours': 'Mon–Fri 09:00–18:00, Sat 10:00–14:00'})
    ..reply('GET', '/chat/threads/th-1/messages', [
      chatMessageJson(id: 's0', sender: 'system', kind: 'system', body: {'code': 'consultation_received'}),
      chatMessageJson(id: 'c1', sender: 'system', kind: 'card', body: _request),
      chatMessageJson(
        id: 'q1',
        kind: 'quote',
        body: {
          'booking_id': 'bk-9',
          'final_price': 350000,
          'deposit': 35000,
          'balance': 315000,
          'note': null,
          'service_code': 'move_out',
          'visit_date': '2026-11-19',
          'start_hour': 8,
          'estimate': 346500,
          'answers': {'building': 'officetel', 'layout': 'one_and_half'},
        },
      ),
    ])
    ..reply('POST', '/chat/threads/th-1/read', null);
  stockCustomerApi(fake, threads: [threadJson(id: 'th-1', topic: 'move_out')]);
  return fake;
}

void main() {
  for (final locale in LocaleController.supported) {
    final code = locale.languageCode;
    for (final scale in [1.3, 2.0]) {
      testWidgets('[$code x$scale] chat list and quote card fit a small phone', (tester) async {
        setViewport(tester, _smallPhone);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final t = lookupT(locale);
        final env = await TestEnv.create(fake: _api(), localeCode: code);

        await pumpCustomerScreen(tester, env, const ChatListTab());
        await pumpUntilFound(tester, find.textContaining(t.chatReplyFast));
        expect(tester.takeException(), isNull, reason: 'list');
        await unmount(tester);

        await pumpCustomerScreen(tester, env, const ChatRoomScreen(threadId: 'th-1', topic: 'move_out', bookingId: 'bk-9'));
        await pumpUntilFound(tester, find.text(t.quoteConfirmedTitle));
        expect(find.text(t.quotePayDeposit), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'quote card');
        await unmount(tester);
      });
    }
  }
}
