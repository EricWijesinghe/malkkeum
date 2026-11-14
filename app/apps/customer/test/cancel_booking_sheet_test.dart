import 'package:core/core.dart';
import 'package:customer/screens/cancel_booking_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

final _t = lookupT(const Locale('ko'));

/// A paid 36,300원 booking cancelled 5 days out: 10% fee, the rest refunded.
Json _preview({bool canCancel = true}) => {
  'can_cancel': canCancel,
  'days_before': 5,
  'percent': 10,
  'paid': 36300,
  'fee': 3630,
  'refund': 32670,
  'reschedule_allowed': true,
};

/// Opens the sheet from a button; each confirmed (or dismissed) result is appended to [results].
Future<void> _open(
  WidgetTester tester,
  Json preview,
  List<CancelConfirmation?> results,
) async {
  final fake = FakeApi()..reply('GET', '/bookings/q1/cancel-preview', preview);
  stockCustomerApi(fake);
  final env = await TestEnv.create(fake: fake);
  await pumpCustomerScreen(
    tester,
    env,
    Builder(
      builder: (context) => FilledButton(
        onPressed: () async =>
            results.add(await confirmCancelBooking(context, 'q1')),
        child: const Text('open'),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await pumpUntilFound(tester, find.text(_t.cancelKeep));
}

void main() {
  testWidgets(
    'shows the fee tier, fee, refund, method and the refund in the confirm button',
    (tester) async {
      await _open(tester, _preview(), []);

      expect(find.textContaining('10%'), findsOneWidget);
      expect(
        find.text(_t.cancelFeeLine(formatWon(3630, 'ko'))),
        findsOneWidget,
      );
      expect(
        find.text(_t.cancelRefundLine(formatWon(32670, 'ko'))),
        findsOneWidget,
      );
      expect(find.text(_t.cancelMethodLine), findsOneWidget);
      expect(find.text(_t.cancelPolicyLink), findsOneWidget);
      expect(find.text('취소하고 32,670원 환불받기'), findsOneWidget);
    },
  );

  testWidgets(
    'confirming hands back the fee the customer saw and the chosen reason',
    (tester) async {
      final results = <CancelConfirmation?>[];
      await _open(tester, _preview(), results);

      await tester.tap(find.text(_t.cancelReasonSchedule));
      await settle(tester);
      await tester.tap(find.text('취소하고 32,670원 환불받기'));
      await settle(tester);

      expect(results, hasLength(1));
      expect(results.single?.fee, 3630);
      expect(results.single?.reason, 'schedule');
    },
  );

  testWidgets('keeping the booking returns null and no reason is required', (
    tester,
  ) async {
    final results = <CancelConfirmation?>[];
    await _open(tester, _preview(), results);

    await tester.tap(find.text(_t.cancelKeep));
    await settle(tester);

    expect(results, [null]);
  });

  testWidgets('a closed cancel window explains why and cannot confirm', (
    tester,
  ) async {
    await _open(tester, _preview(canCancel: false), []);

    expect(find.text(_t.err_cancellation_window_closed), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, _t.cancelBooking),
    );
    expect(confirm.onPressed, isNull);
  });
}
