import 'package:console/screens/growth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

const _packPath = '/admin/growth/welcome-pack';

FakeApi _api() => FakeApi()
  ..reply('GET', '/admin/growth', {
    'welcome': {'enabled': false, 'kind': 'amount', 'value': 5000},
    'welcome_pack': [
      {'amount': 15000, 'service_code': null},
    ],
    'referral': {'enabled': false, 'amount': 5000},
  })
  ..reply('GET', '/admin/reviews/reports', const <Json>[])
  ..reply('GET', '/admin/reviews', const <Json>[])
  ..reply('GET', '/admin/cases', const <Json>[])
  ..reply('GET', '/admin/acquisition', {'rows': const <Json>[]})
  ..onPut(_packPath, (c) => c.body);

void main() {
  testWidgets('growth shows the one 15,000 sign-up coupon and saves an edited pack', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = _api();
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const GrowthSettings());
    await pumpUntilFound(tester, find.text(koT.welcomePackTitle));

    final amount = find.widgetWithText(TextField, koT.welcomePackAmount);
    expect(amount, findsOneWidget);
    expect(tester.widget<TextField>(amount).controller!.text, '15000');

    await tester.enterText(amount, '20000');
    await tester.tap(find.text(koT.welcomePackAdd));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, koT.welcomePackAmount).last, '3000');
    // The pack editor is the first section: its save button is the first one on the screen.
    await tester.tap(find.widgetWithText(FilledButton, koT.save).first);
    await settle(tester, duration: const Duration(milliseconds: 500));
    expect(fake.lastCall('PUT', _packPath)!.body, [
      {'amount': 20000, 'service_code': null},
      {'amount': 3000, 'service_code': null},
    ]);

    // Removing every coupon saves an empty pack (= switched off).
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip(koT.welcomePackRemove).first);
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(FilledButton, koT.save).first);
    await settle(tester, duration: const Duration(milliseconds: 500));
    expect(fake.lastCall('PUT', _packPath)!.body, isEmpty);
    await settle(tester, duration: const Duration(seconds: 4)); // toasts time out
    await unmount(tester);
  });
}
