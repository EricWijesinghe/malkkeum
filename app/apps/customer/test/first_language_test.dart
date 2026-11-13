import 'package:core/core.dart';
import 'package:customer/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';

void main() {
  for (final (device, expected) in [
    (const Locale('en', 'US'), 'en'),
    (const Locale('vi', 'VN'), 'ko'),
  ]) {
    testWidgets(
      'fresh install follows a ${device.languageCode} device as $expected, no picker',
      (tester) async {
        setViewport(tester, phoneSize);
        tester.platformDispatcher.localesTestValue = [device];
        tester.platformDispatcher.localeTestValue = device;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final env = await TestEnv.create(signedIn: false, localeCode: null);

        expect(
          env.locale.locale,
          isNull,
          reason: 'no choice yet: follow the device',
        );
        expect(env.storage.data['app.locale'], isNull);

        await pumpCustomerScreen(tester, env, const IntroScreen());
        await settle(tester);
        expect(find.text(lookupT(Locale(expected)).introStart), findsOneWidget);
        await unmount(tester);
      },
    );
  }

  test('a stored archived language reads English and is rewritten', () async {
    final env = await TestEnv.create(signedIn: false, localeCode: 'vi');
    expect(env.locale.locale, const Locale('en'));
    expect(env.storage.data['app.locale'], 'en');
  });

  test('"follow the device" is remembered', () async {
    final env = await TestEnv.create(signedIn: false);
    await env.locale.set(null);
    expect(env.storage.data['app.locale'], 'system');
    final again = LocaleController(storage: env.storage);
    await again.restore();
    expect(again.locale, isNull);
  });
}
