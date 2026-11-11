import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

const _version = '2026-11-17';

Map<String, Object?> _consents({bool marketing = false}) => {
  'version': _version,
  'reconsent_required': false,
  'items': [
    {'kind': 'terms', 'required': true, 'granted': true, 'granted_at': null},
    {'kind': 'privacy', 'required': true, 'granted': true, 'granted_at': null},
    {'kind': 'overseas_transfer', 'required': true, 'granted': true, 'granted_at': null},
    {'kind': 'marketing', 'required': false, 'granted': marketing, 'granted_at': null},
  ],
};

/// More -> 계정 (AccountScreen). The More list is lazy, so the row is scrolled to first.
Future<void> _openAccount(WidgetTester tester) async {
  await pumpUntilFound(tester, find.text(koT.tabMore));
  await tester.tap(find.text(koT.tabMore));
  await settle(tester);
  await tester.scrollUntilVisible(
    find.text(koT.moreAccount),
    200,
    scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)),
  );
  await tester.tap(find.text(koT.moreAccount));
  await settle(tester);
}

void main() {
  testWidgets('marketing can be granted and saved with the policy version; required consents stay on', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    fake.reply('GET', '/me/consents', _consents());
    fake.reply('PUT', '/me/consents', _consents(marketing: true));
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);
    await _openAccount(tester);

    await tester.tap(find.text(koT.pvManage));
    await settle(tester);
    expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('consent-terms'))).onChanged, isNull, reason: 'required consent is locked');

    await tester.tap(find.byKey(const ValueKey('consent-marketing')));
    await settle(tester);
    await tester.tap(find.text(koT.save));
    await settle(tester);

    final body = fake.lastCall('PUT', '/me/consents')!.json;
    final sent = (body['consents'] as List).cast<Map<String, dynamic>>();
    expect(sent.firstWhere((c) => c['kind'] == 'marketing'), {'kind': 'marketing', 'granted': true, 'version': _version});
    expect(sent.length, 4, reason: 'every item is sent so the server records the full state');
  });

  testWidgets('data export shows the server document as JSON and offers copy', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    fake.reply('GET', '/me/export', {
      'profile': {'phone': '010-5555-0101', 'name': '지민'},
      'bookings': <Object>[],
    });
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerApp(tester, env);
    await _openAccount(tester);

    await tester.scrollUntilVisible(
      find.text(koT.pvExport),
      200,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)),
    );
    await tester.tap(find.text(koT.pvExport));
    await settle(tester);

    expect(find.textContaining('010-5555-0101'), findsOneWidget);
    expect(find.text(koT.pvCopy), findsOneWidget);
  });
}
