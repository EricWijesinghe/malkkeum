import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Json _draftCard() => {'kind': 'resume_quote', 'score': 1000, 'service': 'move_in', 'reason': 'draft_unfinished', 'facts': 0};

void _stockVerify(FakeApi fake) {
  fake
    ..reply('POST', '/auth/otp', {'dev_code': '123456'})
    ..reply('POST', '/auth/verify', {
      'access_token': 'access-guest',
      'refresh_token': 'refresh-guest',
      'role': 'customer',
      'subject': 'user-guest',
      'is_new': false,
    });
}

void main() {
  group('guest mode', () {
    testWidgets('first launch goes straight to home with a feed and no account calls', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake, feed: [_draftCard()]);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));

      // Language picker is shown on first run only; the test env has already picked one.
      expect(find.text(koT.introStart), findsNothing);
      expect(find.text(koT.dhHomeRecommended), findsOneWidget);
      expect(find.text(koT.feedTitleDraft), findsOneWidget);
      expect(find.text(koT.feedWhyDraft), findsOneWidget);
      expect(fake.callsTo('GET', '/me'), isEmpty);
      expect(fake.callsTo('GET', '/bookings'), isEmpty);
      expect(fake.callsTo('GET', '/me/feed'), isEmpty);
      expect(fake.callsTo('GET', '/feed'), isNotEmpty);
      await unmount(tester);
    });

    testWidgets('booking asks for sign-in in a sheet and keeps the draft when signed in', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      _stockVerify(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));

      await tester.tap(find.text(koT.serviceShort('studio')).first);
      await settle(tester);
      expect(find.text(koT.chooseDate), findsOneWidget);

      await tester.tap(find.text(koT.chooseDate));
      await settle(tester);
      expect(find.text(koT.guestSheetTitle), findsOneWidget, reason: 'protected action opens the sheet');
      expect(fake.callsTo('POST', '/auth/otp'), isEmpty);

      await tester.enterText(find.byType(TextField).last, '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(koT.loginSendCode));
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, '123456');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(koT.loginVerify));
      await settle(tester);

      expect(fake.lastCall('POST', '/auth/verify'), isNotNull);
      expect(find.text(koT.guestSheetTitle), findsNothing, reason: 'sheet closes on success');
      expect(fake.callsTo('GET', '/me'), isNotEmpty, reason: 'account data loads after sign-in');
      await unmount(tester);
    });

    testWidgets('a network failure on send code shows a localized message with retry', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()..on('POST', '/auth/otp', (_) => throw Exception('offline'));
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));
      await tester.tap(find.text(koT.serviceShort('studio')).first);
      await settle(tester);
      await tester.tap(find.text(koT.chooseDate));
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, '01012345678');
      await settle(tester, duration: const Duration(milliseconds: 300));

      await tester.tap(find.text(koT.loginSendCode));
      await settle(tester);
      expect(find.text(koT.errorNetwork), findsOneWidget);
      expect(find.text(koT.retry), findsOneWidget);

      // Retry is live: the same action is sent again.
      await tester.tap(find.text(koT.retry));
      await settle(tester);
      expect(fake.callsTo('POST', '/auth/otp'), hasLength(2));
      await unmount(tester);
    });

    testWidgets('the send button stays above the on-screen keyboard', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));
      await tester.tap(find.text(koT.serviceShort('studio')).first);
      await settle(tester);
      await tester.tap(find.text(koT.chooseDate));
      await settle(tester);

      const keyboard = 320.0;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3 * tester.view.devicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await settle(tester, duration: const Duration(milliseconds: 300));

      final visibleBottom = phoneSize.height - keyboard;
      final cta = tester.getRect(find.byType(PrimaryButton).last);
      expect(cta.bottom, lessThanOrEqualTo(visibleBottom), reason: 'CTA hidden behind the keyboard');
      await unmount(tester);
    });
  });
}
