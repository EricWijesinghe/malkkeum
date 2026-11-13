import 'dart:async';

import 'package:core/core.dart';
import 'package:customer/screens/addresses.dart';
import 'package:customer/screens/payments.dart';
import 'package:customer/screens/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Runs the three accessibility guidelines the release checklist requires.
Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    final name = mode.name;

    testWidgets('intro screen meets tap-target and contrast guidelines ($name)', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      final env = await TestEnv.create(signedIn: false, themeMode: mode);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('home screen meets tap-target and contrast guidelines ($name)', (tester) async {
      setViewport(tester, tallPhoneSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi();
      stockCustomerApi(fake, name: '지민');
      final env = await TestEnv.create(fake: fake, themeMode: mode);
      await pumpCustomerApp(tester, env);
      await pumpUntilFound(tester, find.text(koT.service('studio')));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('service detail meets tap-target and contrast guidelines ($name)', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, themeMode: mode);
      await pumpCustomerScreen(tester, env, ServiceScreen(service: Service.fromJson(serviceJson('bathroom'))));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('address search with results meets tap-target and contrast guidelines ($name)', (tester) async {
      setViewport(tester, tallPhoneSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi()
        ..reply('GET', '/features', {'address_search': true, 'card_billing': false})
        ..reply('GET', '/address/search', {
          'results': [
            {'road_address': '서울특별시 마포구 월드컵북로 400', 'jibun_address': '서울 마포구 상암동 1', 'zip_code': '03922', 'building_name': '상암'},
          ],
          'page': 1,
        });
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, themeMode: mode);
      await pumpCustomerScreen(tester, env, const AddressFormScreen());
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, koT.addressRoad), '상암동');
      await tester.tap(find.widgetWithText(FilledButton, koT.addressSearchButton));
      await pumpUntilFound(tester, find.text('서울특별시 마포구 월드컵북로 400'));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('saved cards meet tap-target and contrast guidelines ($name)', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi()
        ..reply('GET', '/payments/methods', [
          {'code': 'card', 'flow': 'billing'},
          {'code': 'kakaopay', 'flow': 'billing'},
        ])
        ..reply('GET', '/me/payment-methods/setup', {'enabled': true, 'store_id': 'store-1', 'channels': {'card': 'ch-card', 'kakaopay': 'ch-kp'}, 'issue_id': 'iss-1'});
      stockCustomerApi(fake, methods: [paymentMethodJson()]);
      final env = await TestEnv.create(fake: fake, themeMode: mode);
      final app = await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
      unawaited(app.loadMethods());
      await pumpUntilFound(tester, find.text(koT.apPayManageTitle));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });
  }
}
