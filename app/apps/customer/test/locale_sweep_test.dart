import 'package:core/core.dart';
import 'package:customer/screens/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Smallest phone we support (iPhone SE 1st gen class) at a larger system font: the worst case
/// for long translations. Any RenderFlex overflow or exception fails the test.
const _smallPhone = Size(320, 568);
const _bigFont = 1.3;

FakeApi _richApi() {
  final fake = FakeApi();
  stockCustomerApi(
    fake,
    name: 'Nguyễn Thị Phương Thảo',
    bookings: [
      bookingJson(id: 'b1', status: 0, serviceCode: 'move_out', estimate: 420000),
      bookingJson(id: 'b2', status: 2, serviceCode: 'aircon', finalPrice: 89000, paidAmount: 89000),
      bookingJson(id: 'b3', status: 3, serviceCode: 'studio', finalPrice: 59000, paidAmount: 59000, balancePaid: true),
    ],
    threads: [
      threadJson(id: 't1', unreadMember: 3, lastMessage: {'kind': 'text', 'body': {'text': 'Xin chào! Chúng tôi sẽ đến lúc 9 giờ sáng.'}, 'sender': 'staff'}),
    ],
  );
  return fake;
}

void main() {
  for (final locale in LocaleController.supported) {
    final code = locale.languageCode;

    testWidgets('[$code] every customer tab fits a small phone with large text', (tester) async {
      setViewport(tester, _smallPhone);
      tester.platformDispatcher.textScaleFactorTestValue = _bigFont;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final t = lookupT(locale);
      final env = await TestEnv.create(fake: _richApi(), localeCode: code);

      await pumpCustomerApp(tester, env);
      await pumpUntilFound(tester, find.text(t.tabHome));
      await settle(tester, duration: const Duration(milliseconds: 600));
      for (final tab in [t.tabBookings, t.tabChat, t.tabMore, t.tabHome]) {
        await tester.tap(find.text(tab).last);
        await settle(tester, duration: const Duration(milliseconds: 600));
      }
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('[$code] intro and every service screen fit a small phone', (tester) async {
      setViewport(tester, _smallPhone);
      tester.platformDispatcher.textScaleFactorTestValue = _bigFont;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fake = _richApi();
      final env = await TestEnv.create(fake: fake, localeCode: code, signedIn: false);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 600));
      final intro = tester.takeException();
      expect(intro, isNull, reason: 'intro: ${intro is FlutterError ? intro.toStringDeep() : intro}');
      await unmount(tester);

      final signedIn = await TestEnv.create(fake: fake, localeCode: code);
      for (final s in catalogCodes) {
        await pumpCustomerScreen(tester, signedIn, ServiceScreen(service: Service.fromJson(serviceJson(s))));
        await settle(tester, duration: const Duration(milliseconds: 400));
        final e = tester.takeException();
        expect(e, isNull, reason: 'service $s: ${e is FlutterError ? e.toStringDeep() : e}');
        await unmount(tester);
      }
    });
  }
}
