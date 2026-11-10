import 'package:console/screens/inbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

Finder _paletteField() => find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == koT.cPaletteHint);

void main() {
  testWidgets('Ctrl+K opens the command palette and a matching entry navigates there', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi();
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleApp(tester, env);
    await settle(tester, duration: const Duration(milliseconds: 500));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(_paletteField(), findsOneWidget);

    await tester.enterText(_paletteField(), koT.cInbox);
    await settle(tester, duration: const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ListTile, koT.cInbox).last);
    await settle(tester);

    expect(_paletteField(), findsNothing, reason: 'palette closes after picking');
    expect(find.byType(InboxScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the search button in the app bar opens the same palette', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleApp(tester, env);
    await settle(tester, duration: const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip(koT.cSearchCommand).first);
    await settle(tester);
    expect(_paletteField(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a booking number typed into the palette offers an open-booking entry', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi();
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleApp(tester, env);
    await settle(tester, duration: const Duration(milliseconds: 500));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    await tester.enterText(_paletteField(), 'B-20260101-0001');
    await settle(tester, duration: const Duration(milliseconds: 300));
    expect(find.text('${koT.cOpenBooking}: B-20260101-0001'), findsOneWidget);
    await unmount(tester);
  });
}
