@Tags(['golden'])
library;

import 'package:core/core.dart';
import 'package:customer/screens/bookings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Booking card in each status, light and dark. Baselines live in `goldens/bookings/` and are
/// generated and compared on the CI runner only (fonts differ per machine).
void main() {
  final visit = DateTime(2026, 11, 19);
  const names = {0: 'consultation', 1: 'confirmed', 2: 'matched', 3: 'completed', -1: 'cancelled'};

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final status in names.keys) {
      testWidgets('booking card ${names[status]} ${mode.name}', (tester) async {
        setViewport(tester, const Size(360, 280));
        final fake = FakeApi();
        stockCustomerApi(fake);
        final env = await TestEnv.create(fake: fake, themeMode: mode);
        final booking = Booking.fromJson(
          bookingJson(
            status: status,
            serviceCode: status == 0 ? 'move_in' : 'studio',
            visitDate: visit,
            answers: status == 0 ? const {} : null,
          ),
        );
        await pumpCustomerScreen(
          tester,
          env,
          Scaffold(
            // Top-aligned so the card keeps its own height instead of filling the body.
            body: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BookingCard(booking: booking),
              ),
            ),
          ),
        );
        await settle(tester, duration: const Duration(milliseconds: 600));

        await expectLater(
          find.byType(BookingCard),
          matchesGoldenFile('goldens/bookings/card_${names[status]}_${mode.name}.png'),
        );
        await unmount(tester);
      });
    }
  }
}
