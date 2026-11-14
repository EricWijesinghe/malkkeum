import 'package:customer/screens/reschedule_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Pumps the gate over a fixed cancel preview with [allowed] as the server's reschedule flag.
Future<void> _pump(WidgetTester tester, {required bool allowed}) async {
  final fake = FakeApi()
    ..reply('GET', '/bookings/q1/cancel-preview', {
      'can_cancel': true,
      'days_before': 5,
      'percent': null,
      'paid': 36300,
      'fee': 0,
      'refund': 36300,
      'reschedule_allowed': allowed,
    });
  stockCustomerApi(fake);
  final env = await TestEnv.create(fake: fake);
  await pumpCustomerScreen(
    tester,
    env,
    const RescheduleGate(bookingId: 'q1', child: Text('reschedule-entry')),
  );
}

void main() {
  testWidgets('shows the reschedule entry when the server allows it', (
    tester,
  ) async {
    await _pump(tester, allowed: true);
    await pumpUntilFound(tester, find.text('reschedule-entry'));
    expect(find.text('reschedule-entry'), findsOneWidget);
  });

  testWidgets('hides the reschedule entry when the server refuses it', (
    tester,
  ) async {
    await _pump(tester, allowed: false);
    await tester.pumpAndSettle();
    expect(find.text('reschedule-entry'), findsNothing);
  });
}
