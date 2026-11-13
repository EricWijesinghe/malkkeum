import 'dart:async';

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:customer/screens/addresses.dart';
import 'package:customer/screens/pay_method_picker.dart';
import 'package:customer/screens/payments.dart';
import 'package:customer/screens/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

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

/// Saved-card channels (PortOne configured) plus one checkout channel: the picker shows both kinds.
void _stockPayments(FakeApi fake) {
  fake
    ..reply('GET', '/payments/methods', [
      {'code': 'card', 'flow': 'billing'},
      {'code': 'kakaopay', 'flow': 'billing'},
      {'code': 'transfer', 'flow': 'checkout'},
    ])
    ..reply('GET', '/features', {'address_search': true, 'card_billing': true})
    ..reply('GET', '/me/payment-methods/setup', {'enabled': true, 'store_id': 'store-1', 'channels': {'card': 'ch-card', 'kakaopay': 'ch-kp'}, 'issue_id': 'iss-1'})
    ..reply('GET', '/address/search', {
      'results': [
        for (final i in [1, 2, 3])
          {'road_address': '서울특별시 마포구 월드컵북로 $i$i$i', 'jibun_address': '서울특별시 마포구 상암동 1$i', 'zip_code': '03922', 'building_name': '상암 아파트 $i동'},
      ],
      'page': 1,
    });
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

    testWidgets('[$code] address search results, typed fallback, saved cards and the pay picker fit a small phone', (tester) async {
      setViewport(tester, _smallPhone);
      tester.platformDispatcher.textScaleFactorTestValue = _bigFont;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final t = lookupT(locale);
      final fake = _richApi();
      _stockPayments(fake);
      final env = await TestEnv.create(fake: fake, localeCode: code);

      await pumpCustomerScreen(tester, env, const AddressFormScreen());
      await settle(tester, duration: const Duration(milliseconds: 400));
      await tester.enterText(find.widgetWithText(TextField, t.addressRoad), '상암동 1');
      await tester.tap(find.widgetWithText(FilledButton, t.addressSearchButton));
      await pumpUntilFound(tester, find.text('서울특별시 마포구 월드컵북로 111'));
      await settle(tester, duration: const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'address results');
      // Picking a result fills the address field.
      await tester.ensureVisible(find.text('서울특별시 마포구 월드컵북로 111'));
      await tester.pump();
      await tester.tap(find.text('서울특별시 마포구 월드컵북로 111'));
      await settle(tester, duration: const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'picked address');
      await unmount(tester);

      final picker = await pumpCustomerScreen(
        tester,
        env,
        Scaffold(body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [PayMethodPicker(onChoose: (_) {})])),
      );
      unawaited(picker.loadMethods());
      await pumpUntilFound(tester, find.text(t.payMethod('kakaopay')));
      await settle(tester, duration: const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'pay method picker');
      await unmount(tester);

      final saved = await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
      unawaited(saved.loadMethods());
      await pumpUntilFound(tester, find.text(t.apPayManageTitle));
      expect(find.text('신한 1234'), findsOneWidget, reason: 'saved card is listed');
      await settle(tester, duration: const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'saved cards');
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
