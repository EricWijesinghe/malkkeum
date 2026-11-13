import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Json _offers({required bool welcome, required bool referral}) => {
  'welcome': {'enabled': welcome, 'kind': 'percent', 'value': 10},
  'welcome_pack': const <Json>[],
  'referral': {'enabled': referral, 'amount': 3000},
  'coupon_days': 14,
};

void main() {
  group('guest tabs and offers', () {
    testWidgets('a guest bookings tab explains the flow, and its CTA opens home, not the sheet', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));

      await tester.tap(find.text(koT.tabBookings));
      await settle(tester);
      expect(find.text(koT.guestFlowTitle), findsOneWidget);
      expect(find.text(koT.guestFlowDone), findsOneWidget);
      expect(fake.callsTo('GET', '/bookings'), isEmpty, reason: 'a guest never loads bookings');

      await tester.tap(find.text(koT.guestFirstQuoteCta));
      await settle(tester);
      expect(find.text(koT.guestSheetTitle), findsNothing);
      expect(find.text(koT.dhHomeRecommended), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a guest chat tab shows the FAQ, and its CTA asks for sign-in with the chat reason', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));

      await tester.tap(find.text(koT.tabChat));
      await settle(tester);
      expect(find.text(koT.guestFaqTitle), findsOneWidget);
      expect(fake.callsTo('POST', '/chat/threads'), isEmpty);

      await tester.tap(find.text(koT.guestChatCta));
      await settle(tester);
      expect(find.text(koT.guestReasonChat), findsOneWidget, reason: 'the sheet names the chat reason');
      await unmount(tester);
    });

    testWidgets('a guest sees the welcome line and the referral amount while those offers are on', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()..reply('GET', '/public/offers', _offers(welcome: true, referral: true));
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));

      expect(find.text(koT.welcomeOfferLine('10%', '14')), findsOneWidget);
      expect(find.text(koT.referralTitle), findsOneWidget);
      expect(find.text(koT.referralOfferLine(formatWon(3000, 'ko'))), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('offers that are off hide their lines and the guest referral card', (tester) async {
      setViewport(tester, phoneSize);
      final fake = FakeApi()..reply('GET', '/public/offers', _offers(welcome: false, referral: false));
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 500));

      expect(find.text(koT.welcomeOfferLine('10%', '14')), findsNothing);
      expect(find.text(koT.referralTitle), findsNothing);
      await unmount(tester);
    });
  });
}
