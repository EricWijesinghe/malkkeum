import 'package:core/core.dart';
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
      addTearDown(handle.dispose);
      final env = await TestEnv.create(signedIn: false, themeMode: mode);
      await pumpCustomerApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
    });

    testWidgets('home screen meets tap-target and contrast guidelines ($name)', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      final fake = FakeApi();
      stockCustomerApi(fake, name: '지민');
      final env = await TestEnv.create(fake: fake, themeMode: mode);
      await pumpCustomerApp(tester, env);
      await pumpUntilFound(tester, find.text(koT.homeServices));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
    });

    testWidgets('service detail meets tap-target and contrast guidelines ($name)', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      final fake = FakeApi();
      stockCustomerApi(fake);
      final env = await TestEnv.create(fake: fake, themeMode: mode);
      await pumpCustomerScreen(tester, env, ServiceScreen(service: Service.fromJson(serviceJson('bathroom'))));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
    });
  }
}
