import 'package:core/core.dart';
import 'package:customer/screens/more.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';

// Noon UTC keeps the calendar date 2026-11-14 in every timezone from UTC-11 to UTC+11.
const _postedAt = '2026-11-14T12:00:00Z';

void main() {
  testWidgets('a notice row shows its posting date', (tester) async {
    final env = await TestEnv.create(
      fake: FakeApi()
        ..reply('GET', '/content', [
          contentJson(kind: 'notice', createdAt: _postedAt),
        ]),
    );
    await pumpCustomerScreen(
      tester,
      env,
      const Scaffold(body: ContentListBody(kind: 'notice')),
    );
    await settle(tester);
    expect(find.text('2026.11.14'), findsOneWidget);
  });

  testWidgets('the notice detail header shows the posting date', (
    tester,
  ) async {
    final env = await TestEnv.create();
    final item = ContentItem(contentJson(kind: 'notice', createdAt: _postedAt));
    await pumpCustomerScreen(tester, env, ContentDetailScreen(item: item));
    await settle(tester);
    expect(find.text('2026.11.14'), findsOneWidget);
  });

  testWidgets('no date is drawn when the server sent none', (tester) async {
    final env = await TestEnv.create();
    final item = ContentItem(contentJson(kind: 'notice'));
    await pumpCustomerScreen(tester, env, ContentDetailScreen(item: item));
    await settle(tester);
    expect(find.textContaining('.'), findsNothing);
  });
}
