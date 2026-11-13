import 'dart:async';
import 'dart:io';

import 'package:console/screens/dashboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';

void main() {
  late bool online;
  late TestEnv env;

  setUp(() async {
    online = true;
    final fake = FakeApi()
      ..onGet('/admin/dashboard', (_) {
        if (!online) throw const SocketException('no signal');
        return {'today_jobs': 7, 'unassigned': 3, 'unread_threads': 0, 'open_quotes': 0};
      });
    env = await TestEnv.create(fake: fake, role: 'staff_admin');
  });

  testWidgets('a failed first load shows an error with retry, never a dashboard of zeros', (tester) async {
    setViewport(tester, wideSize);
    online = false;
    final state = await pumpConsoleScreen(tester, env, const DashboardScreen());
    unawaited(state.loadDashboard());
    await pumpUntilFound(tester, find.byType(ErrorRetry));

    expect(find.text(koT.errorNetwork), findsOneWidget);
    expect(find.text(koT.cTodayJobs), findsNothing, reason: 'no KPI tiles without numbers');
    expect(find.text('0'), findsNothing);

    online = true;
    await tester.tap(find.text(koT.retry));
    await pumpUntilFound(tester, find.text('7'));
    expect(find.text(koT.cTodayJobs), findsOneWidget);
    expect(find.byType(ErrorRetry), findsNothing);
    await unmount(tester);
  });

  testWidgets('before the first answer the dashboard shows placeholders, not zeros', (tester) async {
    setViewport(tester, wideSize);
    await pumpConsoleScreen(tester, env, const DashboardScreen());
    await settle(tester, duration: const Duration(milliseconds: 300));

    expect(find.byType(Skeleton), findsWidgets);
    expect(find.text(koT.cTodayJobs), findsNothing);
    await unmount(tester);
  });

  testWidgets('a failed refresh keeps the last numbers and says they are stale', (tester) async {
    setViewport(tester, wideSize);
    final state = await pumpConsoleScreen(tester, env, const DashboardScreen());
    unawaited(state.loadDashboard());
    await pumpUntilFound(tester, find.text('7'));

    online = false;
    unawaited(state.loadDashboard());
    await pumpUntilFound(tester, find.byType(ErrorRetry));

    expect(find.text('7'), findsOneWidget, reason: 'the last good numbers stay');
    expect(find.text('3'), findsOneWidget);
    expect(find.text(koT.errorNetwork), findsOneWidget);

    online = true;
    await tester.tap(find.text(koT.retry));
    await settle(tester, duration: const Duration(seconds: 1));
    expect(find.byType(ErrorRetry), findsNothing);
    await unmount(tester);
  });
}
