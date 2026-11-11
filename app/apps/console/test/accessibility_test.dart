import 'package:console/screens/bookings.dart';
import 'package:console/screens/people.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';
import 'support/payout_fixtures.dart';

Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('login screen meets tap-target and contrast guidelines (${mode.name})', (tester) async {
      setViewport(tester, wideSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi();
      stockConsoleApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false, themeMode: mode);
      await pumpConsoleApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('bookings split view meets tap-target and contrast guidelines (${mode.name})', (tester) async {
      setViewport(tester, wideSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi()..reply('GET', '/admin/bookings', [bookingJson(id: 'bk-1', number: 'B-20260101-0001')]);
      stockConsoleApi(fake);
      final env = await TestEnv.create(fake: fake, role: 'staff_admin', themeMode: mode);
      await pumpConsoleScreen(tester, env, const BookingsScreen());
      await pumpUntilFound(tester, find.text(koT.cSelectBooking));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('payouts tab with rows meets tap-target and contrast guidelines (${mode.name})', (tester) async {
      setViewport(tester, wideSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi()..reply('GET', '/admin/settlements/payouts', payoutRows);
      stockConsoleApi(fake);
      final env = await TestEnv.create(fake: fake, role: 'staff_admin', themeMode: mode);
      await pumpConsoleScreen(tester, env, const SettlementsScreen(initialPayouts: true));
      await pumpUntilFound(tester, find.text(koT.poState_requested));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });
  }
}
