import 'package:console/screens/marketing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

const _banner = <String, Object?>{
  'id': 'c-1',
  'kind': 'banner',
  'slug': null,
  'title': {'ko': '첫 청소 15,000원 쿠폰 즉시 지급'},
  'body': {
    'theme': 'sun',
    'text': {'ko': '신규 고객 웰컴 쿠폰'},
    'card': {
      'label': {'ko': '웰컴 혜택'},
      'value': {'ko': '15,000원'},
    },
  },
  'image_url': null,
  'link': 'coupons',
  'sort_order': 0,
  'active': true,
};

void main() {
  testWidgets('editing a banner keeps its art card and the body keys the form does not show', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/content', [_banner])
      ..onPut('/admin/content/c-1', (call) => call.json);
    stockConsoleApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const MarketingScreen());
    await settle(tester);
    await tester.tap(find.text(koT.cContent));
    await settle(tester);

    await tester.tap(find.text('첫 청소 15,000원 쿠폰 즉시 지급'));
    await settle(tester, duration: const Duration(milliseconds: 500));
    expect(find.widgetWithText(TextField, '15,000원'), findsOneWidget, reason: 'the card value is editable');
    await tester.enterText(find.widgetWithText(TextField, '15,000원'), '20,000원');
    await tester.tap(find.widgetWithText(FilledButton, koT.save));
    await settle(tester, duration: const Duration(milliseconds: 500));

    final body = fake.lastCall('PUT', '/admin/content/c-1')!.json['body'] as Map;
    expect(body['theme'], 'sun', reason: 'keys the form does not edit survive a save');
    expect((body['card'] as Map)['label'], {'ko': '웰컴 혜택'});
    expect((body['card'] as Map)['value'], {'ko': '20,000원'});
    expect(body['text'], {'ko': '신규 고객 웰컴 쿠폰'});
    await unmount(tester);
  });
}
