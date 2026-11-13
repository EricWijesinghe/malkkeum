import 'package:core/core.dart';
import 'package:customer/screens/addresses.dart';
import 'package:customer/screens/more.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// The More sub-pages against the design: coupons (p24), address management (p25), FAQ (p27).
void main() {
  testWidgets('coupons split into usable and used sections with the count, the short date and the note', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, coupons: [
      couponJson(id: 'c1', name: 'welcome', amount: 5000, expiresAt: DateTime(2026, 11, 26, 12)),
      couponJson(id: 'c2', name: 'welcome', amount: 7000, serviceCode: 'aircon'),
      couponJson(id: 'c3', name: 'welcome', amount: 10000, usedBookingId: 'b1'),
    ]);
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const CouponsScreen());
    await app.loadCoupons();
    await settle(tester);

    expect(find.text('${koT.couponsAvailableTitle} ${koT.moreCouponCount('2')}'), findsOneWidget);
    expect(find.text(koT.couponsUsedTitle), findsOneWidget);
    expect(find.text('${koT.couponAnyService} · ${koT.couponUntil('11.26')}'), findsOneWidget, reason: 'M.d until');
    expect(find.text(koT.couponUsed), findsOneWidget, reason: 'used stub');
    expect(find.text(koT.couponsNote), findsOneWidget);
    final usedTop = tester.getTopLeft(find.text(koT.couponUsed)).dy;
    expect(usedTop, greaterThan(tester.getTopLeft(find.text(koT.couponsUsedTitle)).dy), reason: 'used tickets sit under their heading');
    await unmount(tester);
  });

  testWidgets('addresses filter by the home and office tabs and show "address · size"', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, addresses: [
      addressJson(id: 'a1', label: '우리집', sizePyeong: 8),
      addressJson(id: 'a2', kind: 'office', label: '본사', sizePyeong: 24),
    ]);
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const AddressesScreen());
    await app.loadAddresses();
    await settle(tester);

    expect(find.text('우리집'), findsOneWidget);
    expect(find.text('본사'), findsNothing);
    expect(find.textContaining('· ${koT.pyeong('8')}'), findsOneWidget);

    await tester.tap(find.text(koT.addressOffice));
    await settle(tester);
    expect(find.text('본사'), findsOneWidget);
    expect(find.text('우리집'), findsNothing);
    await unmount(tester);
  });

  testWidgets('FAQ chips filter by category and the answer opens under a Q row', (tester) async {
    setViewport(tester, phoneSize);
    Json faq(String id, String q, String? cat) => {
      ...contentJson(id: id, kind: 'faq', title: {'ko': q}),
      'body': {'text': {'ko': '답변 $id'}, 'category': ?cat},
    };
    final fake = FakeApi()
      ..reply('GET', '/content', [faq('f1', '예약 질문', 'booking'), faq('f2', '결제 질문', 'payment')]);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const FaqScreen());
    await pumpUntilFound(tester, find.text('결제 질문'));

    expect(find.text(koT.faqAll), findsOneWidget);
    expect(find.text('Q'), findsNWidgets(2));
    await tester.tap(find.text(koT.faqCat_payment));
    await settle(tester);
    expect(find.text('예약 질문'), findsNothing);
    expect(find.text('결제 질문'), findsOneWidget);

    await tester.tap(find.text('결제 질문'));
    await settle(tester);
    expect(find.text('답변 f2'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('FAQ without categories shows no chip row', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('GET', '/content', [
        {...contentJson(id: 'f1', kind: 'faq', title: const {'ko': '질문'}), 'body': {'text': {'ko': '답'}}},
      ]);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const FaqScreen());
    await pumpUntilFound(tester, find.text('질문'));

    expect(find.text(koT.faqAll), findsNothing);
    await unmount(tester);
  });
}
