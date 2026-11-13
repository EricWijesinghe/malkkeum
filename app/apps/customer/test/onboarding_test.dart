import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Guests browse freely; the phone sign-in opens from the first protected action (booking).
Future<void> openSignInFromBooking(WidgetTester tester) async {
  await tester.tap(find.text(koT.service('studio')).first);
  await settle(tester);
  await tester.tap(find.text(koT.dfBookNow));
  await settle(tester);
}

void main() {
  group('sign-in journey', () {
    testWidgets('sheet -> phone -> code (dev code autofilled) -> verified -> sheet closes', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()
        ..reply('POST', '/auth/otp', {'dev_code': '123456'})
        ..reply('POST', '/auth/verify', {
          'access_token': 'access-new',
          'refresh_token': 'refresh-new',
          'role': 'customer',
          'subject': 'user-new',
          'is_new': false,
        });
      stockCustomerApi(fake, name: '');
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));
      await openSignInFromBooking(tester);

      await tester.enterText(find.byType(TextField).last, '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));
      expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text, '010-1234-5678');
      await tester.tap(find.text(koT.loginSendCode));
      await settle(tester);
      expect(fake.lastCall('POST', '/auth/otp')!.json['phone'], '01012345678');

      // Code step: the dev code is pre-filled, so verify is enabled without typing.
      expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text, '123456');
      await tester.tap(find.text(koT.loginVerify));
      await settle(tester);
      expect(fake.lastCall('POST', '/auth/verify')!.json, containsPair('code', '123456'));
      expect(fake.lastCall('POST', '/auth/verify')!.json, containsPair('audience', 'customer'));
      expect(find.text(koT.guestSheetTitle), findsNothing);
      await unmount(tester);
    });

    testWidgets('send-code stays disabled until the phone number is complete', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));
      await openSignInFromBooking(tester);

      await tester.enterText(find.byType(TextField).last, '0101234');
      await settle(tester, duration: const Duration(milliseconds: 300));
      expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton).last).onPressed, isNull);

      await tester.enterText(find.byType(TextField).last, '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));
      expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton).last).onPressed, isNotNull);
      expect(fake.callsTo('POST', '/auth/otp'), isEmpty);
      await unmount(tester);
    });

    testWidgets('a rejected code clears the field and shows the server error', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()
        ..reply('POST', '/auth/otp', {'dev_code': null})
        ..reply('POST', '/auth/verify', {'error': {'code': 'otp_invalid'}}, status: 401);
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));
      await openSignInFromBooking(tester);
      await tester.enterText(find.byType(TextField).last, '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(koT.loginSendCode));
      await settle(tester);

      // No dev code: the field starts empty, so type six digits by hand.
      await tester.enterText(find.byType(TextField).last, '000000');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(koT.loginVerify));
      await settle(tester);
      expect(find.text(koT.err_otp_invalid), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text, isEmpty);
      await unmount(tester);
    });
  });
}
