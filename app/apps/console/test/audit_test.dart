import 'package:console/screens/audit.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

final _rows = <Json>[
  {
    'id': 2,
    'actor_role': 'staff',
    'actor_id': '0190a000-0000-7000-8000-000000000001',
    'actor_name': '김사장',
    'action': 'case.refund',
    'target': 'case-1',
    'data_text': '{"amount":5000}',
    'created_at': '2026-11-10T00:05:00Z',
  },
  {
    'id': 1,
    'actor_role': 'system',
    'actor_id': null,
    'actor_name': null,
    'action': 'payout.sync',
    'target': 'payout-9',
    'data_text': '',
    'created_at': '2026-11-09T12:00:00Z',
  },
];

void main() {
  test('period chips send Seoul days, inclusive, and "all time" sends no days', () {
    // 2026-11-13 20:00 UTC is already 2026-11-14 in Seoul.
    final now = DateTime.utc(2026, 11, 13, 20);
    expect(auditPeriodQuery(AuditPeriod.today, now), {'from': '2026-11-14', 'to': '2026-11-14'});
    expect(auditPeriodQuery(AuditPeriod.week, now), {'from': '2026-11-08', 'to': '2026-11-14'});
    expect(auditPeriodQuery(AuditPeriod.month, now), {'from': '2026-10-16', 'to': '2026-11-14'});
    expect(auditPeriodQuery(AuditPeriod.all, now), isEmpty);
  });

  test('timestamps are shown in Seoul time', () {
    expect(auditStamp('2026-11-10T00:05:00Z'), '2026.11.10 09:05');
    expect(auditStamp('not a time'), 'not a time');
  });

  test('an unknown action code reads as other, and the code stays in details', () {
    expect(auditActionLabel(koT, 'case.refund'), koT.audActCaseRefund);
    expect(auditActionLabel(koT, 'brand_new.thing'), koT.audOtherAction);
  });

  testWidgets('rows show who, when and a plain action label; a tap shows the recorded text', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()..reply('GET', '/admin/audit', _rows);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const AuditScreen());
    await settle(tester);

    expect(find.text(koT.audActCaseRefund), findsOneWidget);
    expect(find.text('김사장 · 2026.11.10 09:05'), findsOneWidget);
    expect(find.text('${koT.audRoleSystem} · 2026.11.09 21:00'), findsOneWidget, reason: 'a system row is named by its role');
    expect(find.text(koT.audOtherAction), findsOneWidget, reason: 'payout.sync has no plain label yet');

    await tester.tap(find.text(koT.audActCaseRefund));
    await settle(tester);
    expect(find.byWidgetPredicate((w) => w is SelectableText && w.data == '{"amount":5000}'), findsOneWidget);
    expect(find.text('${koT.audActionCode}: case.refund'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the first load asks for the last seven Seoul days', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()..reply('GET', '/admin/audit', <Json>[]);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const AuditScreen());
    await settle(tester);

    final call = fake.lastCall('GET', '/admin/audit')!;
    expect(call.query.containsKey('from'), isTrue);
    expect(call.query['to'], isNotNull);
    expect(call.query.containsKey('actor_role'), isFalse, reason: 'no role filter until one is picked');
    expect(find.text(koT.audEmpty), findsOneWidget);
    await unmount(tester);
  });
}
