import 'package:core/core.dart';
import 'package:customer/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';

void main() {
  testWidgets('fresh install saves the device language and asks once before sign-in', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(signedIn: false, localeCode: null);

    expect(env.locale.firstRun, isTrue);
    expect(env.storage.data['app.locale'], env.locale.effectiveCode, reason: 'saved before any registration');

    await pumpCustomerScreen(tester, env, LanguageWelcome(locale: env.locale, child: const IntroScreen()));
    await settle(tester);
    await tester.tap(find.text(LocaleController.names['vi']!));
    await settle(tester);
    expect(env.storage.data['app.locale'], 'vi');

    final vi = lookupT(const Locale('vi'));
    await tester.tap(find.text(vi.next));
    await settle(tester);
    expect(env.locale.firstRun, isFalse);
    expect(find.byType(IntroScreen), findsOneWidget);
    expect(find.text(vi.introStart), findsOneWidget, reason: 'intro renders in the chosen language');

    final again = LocaleController(storage: env.storage);
    await again.restore();
    expect(again.firstRun, isFalse, reason: 'second launch skips the picker');
    expect(again.locale?.languageCode, 'vi');
    await unmount(tester);
  });

  test('"follow the device" is remembered and is not a first run', () async {
    final env = await TestEnv.create(signedIn: false);
    await env.locale.set(null);
    expect(env.storage.data['app.locale'], 'system');
    final again = LocaleController(storage: env.storage);
    await again.restore();
    expect(again.firstRun, isFalse);
    expect(again.locale, isNull);
  });
}
