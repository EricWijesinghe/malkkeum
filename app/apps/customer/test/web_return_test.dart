import 'package:customer/screens/web_return.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';

void main() {
  test('no hash means no web route (every mobile launch and plain /app/ visit)', () {
    expect(webHashRoute(Uri.parse('https://malkkeum.example/app/')), isNull);
  });

  test('booking deep link and payment return parse from the hash', () {
    final booking = webHashRoute(Uri.parse('https://malkkeum.example/app/#/booking/b-9'));
    expect(booking!.pathSegments, ['booking', 'b-9']);

    final back = webHashRoute(Uri.parse('https://malkkeum.example/app/#/pay-return?paymentId=ck-1&code=USER_CANCEL'));
    expect(back!.path, '/pay-return');
    expect(back.queryParameters['paymentId'], 'ck-1');
    expect(back.queryParameters['code'], 'USER_CANCEL');
  });

  testWidgets('a guest with a booking link gets the sign-in sheet and no booking request', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    final env = await TestEnv.create(fake: fake, signedIn: false);
    await pumpCustomerScreen(
      tester,
      env,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => openWebHashRoute(context, base: Uri.parse('https://malkkeum.example/app/#/booking/b-9')),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);

    expect(find.text(koT.guestReasonBook), findsOneWidget);
    expect(fake.callsTo('GET', '/bookings/b-9'), isEmpty);
    await unmount(tester);
  });
}
