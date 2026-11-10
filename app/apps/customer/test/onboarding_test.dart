import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

void main() {
  group('sign-in journey', () {
    testWidgets('intro -> phone -> code (dev code autofilled) -> profile -> saved', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()
        ..reply('POST', '/auth/otp', {'dev_code': '123456'})
        ..reply('POST', '/auth/verify', {
          'access_token': 'access-new',
          'refresh_token': 'refresh-new',
          'role': 'customer',
          'subject': 'user-new',
          'is_new': true,
        });
      stockCustomerApi(fake, name: '');
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));

      expect(find.text(koT.introStart), findsOneWidget);
      await tester.tap(find.text(koT.introStart));
      await settle(tester);

      await tester.enterText(find.byType(TextField), '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '010-1234-5678');
      await tester.tap(find.text(koT.loginSendCode));
      await settle(tester);
      expect(fake.lastCall('POST', '/auth/otp')!.json['phone'], '01012345678');

      // Code step: the dev code is pre-filled, so verify is enabled without typing.
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '123456');
      await tester.tap(find.text(koT.loginVerify));
      await settle(tester);
      expect(fake.lastCall('POST', '/auth/verify')!.json, containsPair('code', '123456'));
      expect(fake.lastCall('POST', '/auth/verify')!.json, containsPair('audience', 'customer'));

      // A brand-new account lands on the profile step.
      expect(find.text(koT.profileTitle), findsOneWidget);
      await tester.enterText(find.byType(TextField), '민수');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(koT.profileDone));
      await settle(tester);
      expect(fake.lastCall('PATCH', '/me')!.json['name'], '민수');
      expect(find.text(koT.welcomeToast), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('send-code stays disabled until the phone number is complete', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));
      await tester.tap(find.text(koT.introStart));
      await settle(tester);

      await tester.enterText(find.byType(TextField), '0101234');
      await settle(tester, duration: const Duration(milliseconds: 300));
      expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));
      expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed, isNotNull);
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
      await tester.tap(find.text(koT.introStart));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(koT.loginSendCode));
      await settle(tester);

      // No dev code: the field starts empty, so type six digits by hand.
      await tester.enterText(find.byType(TextField), '000000');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(koT.loginVerify));
      await settle(tester);
      expect(find.text(koT.err_otp_invalid), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      await unmount(tester);
    });
  });
}
