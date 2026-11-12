import 'package:core/core.dart';
import 'package:customer/screens/booking_detail.dart';
import 'package:customer/screens/bookings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Smallest supported phone at large system fonts: any RenderFlex overflow or exception fails.
const _smallPhone = Size(320, 568);

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final bookings = [
    bookingJson(id: 'b0', status: 0, serviceCode: 'move_in', visitDate: today, answers: const {}, estimate: 346500),
    bookingJson(id: 'b1', status: 1, serviceCode: 'studio', visitDate: today),
    bookingJson(id: 'b2', status: 2, serviceCode: 'aircon', visitDate: today, startHour: 14),
    bookingJson(id: 'b3', status: 3, serviceCode: 'sofa', visitDate: today),
    bookingJson(id: 'b4', status: -1, serviceCode: 'kitchen', visitDate: today),
  ];

  for (final locale in LocaleController.supported) {
    for (final scale in [1.3, 2.0]) {
      final code = locale.languageCode;

      testWidgets('[$code x$scale] bookings week, month and timeline fit a small phone', (tester) async {
        setViewport(tester, _smallPhone);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fake = FakeApi()..reply('GET', '/bookings/b0', bookings.first);
        stockCustomerApi(fake, bookings: bookings);
        final env = await TestEnv.create(fake: fake, localeCode: code);

        await pumpCustomerScreen(tester, env, const BookingsTab());
        await pumpUntilFound(tester, find.byType(BookingCard));
        await settle(tester, duration: const Duration(milliseconds: 400));
        await tester.tap(find.byKey(const ValueKey('calendar-toggle')));
        await settle(tester, duration: const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);

        await pumpCustomerScreen(tester, env, const BookingDetailScreen(id: 'b0'));
        await pumpUntilFound(tester, find.byType(BookingStatusChip));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }
  }
}
