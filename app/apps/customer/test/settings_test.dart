import 'package:core/core.dart';
import 'package:customer/screens/more.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Future<void> _openMoreTab(WidgetTester tester) async {
  await pumpUntilFound(tester, find.text(koT.tabMore));
  await tester.tap(find.text(koT.tabMore));
  await settle(tester);
}

/// The More list builds rows lazily, so rows below the fold only exist once scrolled to.
Future<void> _scrollMoreTo(WidgetTester tester, String label) => tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.descendant(of: find.byType(MoreTab), matching: find.byType(Scrollable)),
    );

void main() {
  testWidgets('theme defaults to dark and the tile cycles dark -> light -> system -> dark', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    expect(env.theme.mode, ThemeMode.dark, reason: 'dark is the product default');

    await pumpCustomerApp(tester, env);
    await _openMoreTab(tester);
    await _scrollMoreTo(tester, koT.themeTitle);
    expect(find.text(koT.themeLabel(ThemeMode.dark)), findsOneWidget);

    Future<void> tapTheme() async {
      await tester.tap(find.text(koT.themeTitle));
      await settle(tester, duration: const Duration(milliseconds: 500));
    }

    await tapTheme();
    expect(env.theme.mode, ThemeMode.light);
    expect(env.storage.data['app.theme'], 'light', reason: 'choice is persisted');
    expect(find.text(koT.themeLabel(ThemeMode.light)), findsOneWidget);

    await tapTheme();
    expect(env.theme.mode, ThemeMode.system);
    expect(find.text(koT.themeLabel(ThemeMode.system)), findsOneWidget);

    await tapTheme();
    expect(env.theme.mode, ThemeMode.dark);
    await unmount(tester);
  });

  testWidgets('choosing Sinhala then English re-renders the chrome and saves the account language', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('PATCH', '/me', {'name': '지민', 'phone': '01012345678'});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await _openMoreTab(tester);
    await _scrollMoreTo(tester, koT.moreLanguage);
    await tester.tap(find.text(koT.moreLanguage));
    await settle(tester);

    await tester.tap(find.text(LocaleController.names['si']!));
    await settle(tester, duration: const Duration(milliseconds: 500));
    final si = lookupT(const Locale('si'));
    expect(env.locale.locale?.languageCode, 'si');
    expect(env.storage.data['app.locale'], 'si');
    expect(find.text(si.moreLanguage), findsWidgets);
    expect(fake.lastCall('PATCH', '/me')!.json['locale'], 'si');

    await tester.tap(find.text(LocaleController.names['en']!));
    await settle(tester, duration: const Duration(milliseconds: 500));
    final en = lookupT(const Locale('en'));
    expect(env.locale.locale?.languageCode, 'en');
    expect(find.text(en.moreLanguage), findsWidgets, reason: 'language screen re-renders in English');
    expect(fake.lastCall('PATCH', '/me')!.json['locale'], 'en');
    await unmount(tester);
  });
}
