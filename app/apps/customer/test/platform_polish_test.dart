import 'package:customer/main.dart';
import 'package:customer/screens/addresses.dart';
import 'package:customer/screens/payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

void main() {
  testWidgets('system font scale is capped at maxTextScale so large Dynamic Type cannot break layouts', (tester) async {
    setViewport(tester, phoneSize);
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final env = await TestEnv.create();
    await pumpCustomerApp(tester, env);
    await settle(tester);

    final scaler = MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).first));
    expect(scaler.scale(10), closeTo(10 * maxTextScale, 0.001));
    await unmount(tester);
  });

  testWidgets('address list supports pull-to-refresh and reloads from the API', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const AddressesScreen());
    await tester.runAsync(app.loadAddresses);
    await settle(tester);
    final before = fake.callsTo('GET', '/me/addresses').length;

    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await settle(tester, duration: const Duration(seconds: 2));

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(fake.callsTo('GET', '/me/addresses').length, greaterThan(before));
    await unmount(tester);
  });

  testWidgets('saved payment methods support pull-to-refresh and reload the list', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, methods: [paymentMethodJson()]);
    fake.reply('GET', '/payments/methods', const <Map<String, dynamic>>[]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    await settle(tester);
    final before = fake.callsTo('GET', '/me/payment-methods').length;

    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await settle(tester, duration: const Duration(seconds: 2));

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(fake.callsTo('GET', '/me/payment-methods').length, greaterThan(before));
    await unmount(tester);
  });
}
