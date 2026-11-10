import 'package:customer/screens/notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';

void main() {
  testWidgets('inbox lists alerts, marks them read and shows notices on the second tab', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('GET', '/me/notifications', [
        {
          'id': 'n1',
          'kind': 'booking.status',
          'data': {'title': '전문가가 배정됐어요', 'body': '내일 오전 9시 방문', 'data': {'booking_id': 'bk-1'}},
          'read_at': null,
          'created_at': '2026-11-11T01:00:00Z',
        },
      ])
      ..reply('POST', '/me/notifications/read', {'ok': true})
      ..reply('GET', '/content', [
        {'id': 'c1', 'kind': 'notice', 'title': {'ko': '추석 연휴 안내'}, 'body': {'text': {'ko': '...'}}},
      ]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const NotificationsScreen());
    await pumpUntilFound(tester, find.text('전문가가 배정됐어요'));

    expect(fake.lastCall('POST', '/me/notifications/read'), isNotNull, reason: 'opening the inbox reads everything');
    await tester.tap(find.text(koT.moreNotices));
    await settle(tester);
    expect(find.text('추석 연휴 안내'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('unread count ignores read alerts and survives a network error', (tester) async {
    final fake = FakeApi()
      ..reply('GET', '/me/notifications', [
        {'id': 'a', 'kind': 'x', 'data': {}, 'read_at': null, 'created_at': '2026-11-11T01:00:00Z'},
        {'id': 'b', 'kind': 'x', 'data': {}, 'read_at': '2026-11-11T02:00:00Z', 'created_at': '2026-11-11T01:00:00Z'},
      ]);
    final env = await TestEnv.create(fake: fake);
    expect(await unreadAlerts(env.api), 1);
    expect(await unreadAlerts((await TestEnv.create(fake: FakeApi())).api), 0, reason: '404 hides the dot');
  });
}
