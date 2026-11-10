import 'package:console/screens/inbox.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

void main() {
  testWidgets('AI messages carry a badge, the thread can pause and resume the AI, and the month line shows calls', (tester) async {
    setViewport(tester, wideSize);
    // Registration order matters: the first matching route wins, so these come before stockConsoleApi.
    final fake = FakeApi()
      ..reply('GET', '/admin/threads', [threadJson(id: 'th-1', topic: 'studio')])
      ..reply('GET', '/admin/threads/th-1/messages', [
        chatMessageJson(id: 'm-1', sender: 'customer', kind: 'text', body: {'text': '가격 알려주세요'}),
        chatMessageJson(id: 'm-2', kind: 'text', body: {'text': '안내해 드릴게요', 'ai': true}),
      ])
      ..reply('POST', '/admin/threads/th-1/read', null)
      ..reply('GET', '/admin/ai/usage', {
        'configured': true,
        'mode': 'offline',
        'month': {'calls': 7},
      })
      ..reply('PUT', '/admin/threads/th-1/ai', {'id': 'th-1', 'ai_paused': true});
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const InboxScreen());
    await pumpUntilFound(tester, find.text(koT.service('studio')));

    await tester.tap(find.text(koT.service('studio')));
    await settle(tester);

    expect(find.text(koT.aiUsageMonth('7')), findsOneWidget);
    expect(find.text(koT.aiBadge), findsOneWidget, reason: 'only the AI reply is badged');

    await tester.tap(find.text(koT.aiPause));
    await settle(tester);
    final call = fake.lastCall('PUT', '/admin/threads/th-1/ai');
    expect(call, isNotNull);
    expect(call!.body, {'paused': true});
    expect(find.text(koT.aiResume), findsOneWidget);
    expect(find.text(koT.aiPausedNote), findsOneWidget);
    await unmount(tester);
  });
}
