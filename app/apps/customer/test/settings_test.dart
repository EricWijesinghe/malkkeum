import 'package:core/core.dart';
import 'package:customer/screens/business_info.dart';
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

/// Clearly fake seller details, shaped like the public `/brand` business profile.
const Json _brand = {
  'name': '말끔',
  'support_phone': '02-0000-0000',
  'support_email': 'help@example.com',
  'support_hours': '평일 09:00-18:00 (예시)',
  'company': {
    'legal_name': '(주)예시상호',
    'ceo': '홍길동(예시)',
    'registration_no': '000-00-00000',
    'mail_order_no': '제0000-서울예시-0000호',
    'address': '서울특별시 예시구 예시로 1, 예시빌딩 1층',
    'hosting_provider': '예시호스팅(주)',
  },
};

Future<List<Uri>> _pumpBusinessInfo(WidgetTester tester, Json brand, {String localeCode = 'ko'}) async {
  final opened = <Uri>[];
  final env = await TestEnv.create(fake: FakeApi()..reply('GET', '/brand', brand), localeCode: localeCode);
  await pumpCustomerScreen(
    tester,
    env,
    Scaffold(
      body: SingleChildScrollView(child: BusinessInfo(api: env.api, open: (uri) async => opened.add(uri))),
    ),
  );
  await settle(tester);
  return opened;
}

void main() {
  testWidgets('More tab ends with the seller details from /brand', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('GET', '/brand', _brand);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await _openMoreTab(tester);
    await _scrollMoreTo(tester, koT.bizInfoVerify);
    expect(find.text(koT.bizInfoTitle), findsOneWidget);
    final company = _brand['company'] as Json;
    for (final value in company.values) {
      expect(find.textContaining(value as String), findsOneWidget, reason: '$value is shown');
    }
    expect(find.text('02-0000-0000'), findsOneWidget);
    expect(find.text('help@example.com'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('seller details open the FTC lookup, the dialer and mail', (tester) async {
    setViewport(tester, phoneSize);
    final opened = await _pumpBusinessInfo(tester, _brand);

    await tester.tap(find.text(koT.bizInfoVerify));
    await tester.tap(find.text('02-0000-0000'));
    await tester.tap(find.text('help@example.com'));
    expect(opened.map((u) => u.toString()), [
      'https://www.ftc.go.kr/bizCommPop.do?wrkr_no=0000000000',
      'tel:0200000000',
      'mailto:help@example.com',
    ]);
    await unmount(tester);
  });

  testWidgets('seller details hide empty fields, and the whole section when nothing is set', (tester) async {
    setViewport(tester, phoneSize);
    await _pumpBusinessInfo(tester, {
      'name': '말끔',
      'support_phone': ' ',
      'company': {'ceo': '홍길동(예시)', 'registration_no': '000-00', 'address': ''},
    });
    expect(find.textContaining('홍길동(예시)'), findsOneWidget);
    expect(find.textContaining(koT.cSetupAddress), findsNothing);
    expect(find.textContaining(koT.cSetupMailOrderNo), findsNothing);
    expect(find.text(koT.bizInfoVerify), findsNothing, reason: 'no lookup link for an incomplete number');
    expect(find.byType(TextButton), findsNothing);
    await unmount(tester);

    await _pumpBusinessInfo(tester, {'name': '말끔', 'company': <String, dynamic>{}});
    expect(find.text(koT.bizInfoTitle), findsNothing);
    expect(find.byType(Text), findsNothing);
    await unmount(tester);
  });

  for (final locale in LocaleController.supported) {
    testWidgets('seller details fit a phone at large font (${locale.languageCode})', (tester) async {
      setViewport(tester, phoneSize);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpBusinessInfo(tester, _brand, localeCode: locale.languageCode);
      expect(find.text(lookupT(locale).bizInfoTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }
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
