import 'package:core/core.dart';
import 'package:customer/screens/more.dart';
import 'package:customer/screens/payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// U6 screens on the smallest phone at large and largest text, in every language.
/// Any RenderFlex overflow or exception fails the test.
const _smallPhone = Size(320, 568);

FakeApi _api() {
  final fake = FakeApi()
    ..reply('GET', '/me', {
      'name': 'Nguyễn Thị Phương Thảo',
      'phone': '01012345678',
      'email': 'a.very.long.address@example.com',
      'logins': ['kakao', 'naver', 'apple', 'google'],
    })
    ..reply('GET', '/me/points', {'balance': 1234500, 'entries': const <Json>[]})
    ..reply('GET', '/payments/methods', [
      for (final code in ['card', 'kakaopay', 'naverpay', 'tosspay', 'samsungpay', 'transfer'])
        {'code': code, 'flow': 'billing'},
    ])
    ..reply('GET', '/me/payment-methods/setup', {'enabled': true, 'store_id': 'store-1', 'channels': {'card': 'ch-card', 'kakaopay': 'ch-kp'}, 'issue_id': 'iss-1'});
  stockCustomerApi(fake, coupons: [couponJson(id: 'c1', name: 'welcome', amount: 15000)]);
  return fake;
}

void main() {
  for (final locale in LocaleController.supported) {
    for (final scale in [1.3, 2.0]) {
      final code = locale.languageCode;
      testWidgets('[$code x$scale] More, payment methods and account fit a small phone', (tester) async {
        setViewport(tester, _smallPhone);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final t = lookupT(locale);
        final env = await TestEnv.create(fake: _api(), localeCode: code);

        final more = await pumpCustomerScreen(tester, env, const MoreTab());
        await more.loadAll();
        await settle(tester, duration: const Duration(milliseconds: 400));
        await tester.scrollUntilVisible(find.text(t.deleteAccount), 300, scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull, reason: 'more');
        await unmount(tester);

        final pay = await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
        await pay.loadMethods();
        await pumpUntilFound(tester, find.text(t.payAvailableTitle));
        await tester.scrollUntilVisible(find.text(t.apPayManageTitle), 300, scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull, reason: 'payment methods');
        await unmount(tester);

        final account = await pumpCustomerScreen(tester, env, const AccountScreen());
        await account.loadProfile();
        await settle(tester, duration: const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: 'account');
        await unmount(tester);
      });
    }
  }
}
