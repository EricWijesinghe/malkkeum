import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/jobs.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/partner_host.dart';

/// Opens [showQuoteSheet] for booking `bk-7` with a 90,000 customer estimate.
class _SheetHost extends StatelessWidget {
  const _SheetHost();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => showQuoteSheet(context, bookingId: 'bk-7', estimate: 90000),
            child: const Text('open-sheet'),
          ),
        ),
      );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open-sheet'));
  await settle(tester);
}

void main() {
  testWidgets('the pro payout updates live as the quote changes, after the 20% fee', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const _SheetHost());
    await _openSheet(tester);

    // Pre-filled with the estimate: 90,000 minus 18,000 fee.
    expect(find.descendant(of: find.byType(RollingAmount), matching: find.text(formatWon(72000, 'ko'))), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '100000');
    await settle(tester, duration: const Duration(milliseconds: 800));
    expect(find.descendant(of: find.byType(RollingAmount), matching: find.text(formatWon(80000, 'ko'))), findsOneWidget);

    // Fee rounds half-up to the nearest won: 8 * 20% = 1.6 -> 2, so the pro gets 6.
    await tester.enterText(find.byType(TextField).first, '8');
    await settle(tester, duration: const Duration(milliseconds: 800));
    expect(find.descendant(of: find.byType(RollingAmount), matching: find.text(formatWon(6, 'ko'))), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('an empty or zero price cannot be sent', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const _SheetHost());
    await _openSheet(tester);

    final send = find.widgetWithText(PrimaryButton, koT.pSendQuote);
    await tester.enterText(find.byType(TextField).first, '');
    await settle(tester, duration: const Duration(milliseconds: 200));
    expect(tester.widget<PrimaryButton>(send).onPressed, isNull);
    await unmount(tester);
  });

  testWidgets('a double tap on send posts the quote once', (tester) async {
    setViewport(tester, phoneSize);
    final gate = Completer<Object?>();
    final fake = FakeApi()..onPost('/partner/jobs/bk-7/quote', (_) => gate.future);
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const _SheetHost());
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField).first, '50000');
    await settle(tester, duration: const Duration(milliseconds: 200));
    final send = find.widgetWithText(PrimaryButton, koT.pSendQuote);
    await tester.tap(send);
    await tester.pump();
    // While busy the button shows a spinner and cannot be pressed again.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    final busyButton = tester.widget<FilledButton>(find.ancestor(of: find.byType(CircularProgressIndicator).last, matching: find.byType(FilledButton)).first);
    expect(busyButton.onPressed, isNull);
    await tester.tap(find.byType(CircularProgressIndicator).last, warnIfMissed: false);
    await settle(tester);

    gate.complete({'ok': true});
    await settle(tester);
    expect(fake.callsTo('POST', '/partner/jobs/bk-7/quote'), hasLength(1));
    expect(fake.lastCall('POST', '/partner/jobs/bk-7/quote')!.json, containsPair('amount', 50000));
    await unmount(tester);
  });
}
