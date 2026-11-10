import 'package:console/screens/inbox.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

void main() {
  testWidgets('J and K step through threads on the wide layout, clamped at both ends', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/threads', [
        threadJson(id: 'th-1', topic: 'studio'),
        threadJson(id: 'th-2', topic: 'kitchen'),
        threadJson(id: 'th-3', topic: 'bathroom'),
      ])
      ..reply('GET', '/admin/threads/th-1/messages', const <Json>[])
      ..reply('GET', '/admin/threads/th-2/messages', const <Json>[])
      ..reply('GET', '/admin/threads/th-3/messages', const <Json>[])
      ..reply('POST', '/admin/threads/th-1/read', null)
      ..reply('POST', '/admin/threads/th-2/read', null)
      ..reply('POST', '/admin/threads/th-3/read', null);
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const InboxScreen());
    await pumpUntilFound(tester, find.text(koT.service('kitchen')));

    expect(find.text(koT.cSelectThread), findsOneWidget, reason: 'nothing selected at start');

    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await settle(tester);
    expect(find.byKey(const ValueKey('th-1')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await settle(tester);
    expect(find.byKey(const ValueKey('th-2')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await settle(tester);
    expect(find.byKey(const ValueKey('th-1')), findsOneWidget);

    // K at the top stays on the first thread; J past the bottom stops on the last.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await settle(tester);
    expect(find.byKey(const ValueKey('th-1')), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await settle(tester, duration: const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('th-3')), findsOneWidget);
    await unmount(tester);
  });
}
