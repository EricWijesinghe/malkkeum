import 'package:console/screens/renewals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

Finder _paletteField() => find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == koT.cPaletteHint);

Future<void> _openPalette(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await settle(tester);
}

void main() {
  testWidgets('the owner (admin) finds the renewal calendar in the console and it opens', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi();
    stockConsoleApi(fake);
    fake.reply('GET', '/admin/renewals', {'items': const <Object>[]});
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleApp(tester, env);
    await settle(tester, duration: const Duration(milliseconds: 500));

    await _openPalette(tester);
    await tester.enterText(_paletteField(), koT.rnwTitle);
    await settle(tester, duration: const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ListTile, koT.rnwTitle).last);
    await settle(tester);

    expect(find.byType(RenewalsScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a consultant does not see the renewal calendar entry', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi();
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_consultant');
    await pumpConsoleApp(tester, env);
    await settle(tester, duration: const Duration(milliseconds: 500));

    await _openPalette(tester);
    await tester.enterText(_paletteField(), koT.rnwTitle);
    await settle(tester, duration: const Duration(milliseconds: 300));

    expect(find.widgetWithText(ListTile, koT.rnwTitle), findsNothing);
    await unmount(tester);
  });
}
