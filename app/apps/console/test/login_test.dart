import 'package:console/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';

void main() {
  testWidgets('a wrong staff password shows the login-failed message under the password field', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()..reply('POST', '/auth/staff/login', {'error': {'code': 'unauthorized'}}, status: 401);
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, signedIn: false);
    await pumpConsoleApp(tester, env);
    await settle(tester, duration: const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).at(0), 'ops@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await settle(tester, duration: const Duration(milliseconds: 200));
    await tester.tap(find.widgetWithText(PrimaryButton, koT.cLogin));
    await settle(tester);

    final sent = fake.lastCall('POST', '/auth/staff/login')!.json;
    expect(sent['email'], 'ops@example.test');
    expect(sent['password'], 'wrong-password');
    expect(find.text(koT.cLoginFailed), findsOneWidget);
    expect(env.session.signedIn, isFalse);
    await unmount(tester);
  });

  // Known risk: MaterialApp.home is only read when the Navigator is created, so a
  // sign-in that happens on the login route may leave the login screen on top.
  // If this fails, the root route needs rebuilding on session change (see docs).
  testWidgets('a correct staff login opens the console shell', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('POST', '/auth/staff/login', {
        'access_token': 'a-1',
        'refresh_token': 'r-1',
        'role': 'staff_admin',
        'subject': 'staff-1',
      });
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, signedIn: false);
    await pumpConsoleApp(tester, env);
    await settle(tester, duration: const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).at(0), 'ops@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'right-password');
    await tester.tap(find.widgetWithText(PrimaryButton, koT.cLogin));
    await settle(tester);

    expect(env.session.signedIn, isTrue);
    expect(find.byType(ConsoleShell), findsOneWidget);
    await unmount(tester);
  });
}
