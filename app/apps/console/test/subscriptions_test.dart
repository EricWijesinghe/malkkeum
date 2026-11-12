import 'package:console/screens/subscriptions.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

Json _row(String id, String status) => {
  'id': id,
  'user_id': 'u-1',
  'service_code': 'studio',
  'unit_index': null,
  'address_id': 'addr-1',
  'payment_method_id': 'pm-1',
  'preferred_pro_id': null,
  'cadence_weeks': 2,
  'weekday': 1,
  'start_hour': 13,
  'anchor_date': '2026-11-17',
  'status': status,
  'paused_reason': null,
  'discount_percent': 10,
  'consecutive_failures': 0,
  'created_at': '2026-11-01T00:00:00Z',
  'cancelled_at': null,
};

void main() {
  testWidgets('console lists subscriptions and pauses one on the customer\'s behalf', (tester) async {
    final fake = FakeApi()
      ..reply('GET', '/admin/subscriptions', [_row('s-1', 'active'), _row('s-2', 'cancelled')])
      ..reply('POST', '/admin/subscriptions/s-1/pause', _row('s-1', 'paused'));
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const SubscriptionsScreen());
    await pumpUntilFound(tester, find.byKey(const Key('sub-s-1')));

    expect(find.text('${koT.service('studio')} · ${koT.subBiweekly}'), findsNWidgets(2), reason: 'both rows are studio, every two weeks');
    expect(find.byKey(const Key('sub-toggle-s-2')), findsNothing, reason: 'cancelled subscriptions have no toggle');

    await tester.tap(find.byKey(const Key('sub-toggle-s-1')));
    await settle(tester);

    expect(fake.calls.any((c) => c.method == 'POST' && c.path == '/admin/subscriptions/s-1/pause'), isTrue);
    await unmount(tester);
  });

  testWidgets('status filter requests only that status', (tester) async {
    final fake = FakeApi()
      ..reply('GET', '/admin/subscriptions', [_row('s-1', 'active')]);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const SubscriptionsScreen());
    await pumpUntilFound(tester, find.byKey(const Key('sub-s-1')));

    await tester.tap(find.byKey(const Key('sub-filter-paused')));
    await settle(tester);

    final last = fake.calls.lastWhere((c) => c.path == '/admin/subscriptions');
    expect(last.query['status'], 'paused');
    await unmount(tester);
  });
}
