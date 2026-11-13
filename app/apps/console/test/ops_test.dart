import 'package:console/screens/ops.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';

Json _status({required String level}) => {
      'level': level,
      'version': '1.2.3',
      'uptime_secs': 3700,
      'dev_mode': false,
      'db': {'ok': true, 'latency_ms': 4, 'size_bytes': 52428800, 'sessions': 3, 'pool_open': 2, 'pool_idle': 1},
      'disk': {'total_bytes': 100, 'free_bytes': 8, 'free_pct': 8.0},
      'backup': null,
      'checks': [
        {'key': 'db', 'level': 'green', 'value': 4},
        {'key': 'disk', 'level': 'red', 'value': 8},
        {'key': 'backup', 'level': 'red', 'value': null},
        {'key': 'errors', 'level': 'green', 'value': 2},
        {'key': 'payments', 'level': 'green', 'value': 0},
        {'key': 'webhook', 'level': 'green', 'value': 0},
      ],
      'integrations': [
        {
          'code': 'solapi',
          'configured': true,
          'level': 'red',
          'last_ok_at': '2026-11-10T09:00:00Z',
          'last_fail_at': '2026-11-11T01:00:00Z',
          'last_error': 'provider_error',
        },
        {'code': 'portone', 'configured': false, 'level': 'yellow', 'last_ok_at': null, 'last_fail_at': null, 'last_error': null},
        {'code': 'backup', 'configured': false, 'level': 'yellow', 'last_ok_at': null, 'last_fail_at': null, 'last_error': null},
      ],
      'jobs': [
        {'job': 'reconciler', 'last_run_unix': 1794500000.0, 'last_ok_unix': 1794500000.0, 'errors': 0, 'stalled': false},
        {'job': 'notify_outbox', 'last_run_unix': 1794500000.0, 'last_ok_unix': 0.0, 'errors': 3, 'stalled': true},
      ],
    };

const _alerts = <String, Object?>{
  'prefs': {
    'rules': {'sms_failing': true},
    'quiet_start': 22,
    'quiet_end': 7,
    'alert_phone': null,
  },
  'rules': ['sms_failing', 'disk_low'],
  'default_phone': '021234567',
  'cooldown_hours': 6,
};

const _config = <String, Object?>{
  'flags': {'booking': true, 'chat': true, 'ai': true, 'payments': true},
  'maintenance': {'on': false, 'message': ''},
};

const _errors = <String, Object?>{'items': <Object?>[]};

void main() {
  testWidgets('a red disk check shows its Korean action line and the server level', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/ops/status', _status(level: 'red'))
      ..reply('GET', '/admin/ops/alerts', _alerts)
      ..reply('GET', '/admin/config', _config)
      ..reply('GET', '/admin/client-errors', _errors);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const OpsScreen());
    await settle(tester);

    expect(find.text(koT.oLevelRed), findsWidgets);
    expect(find.text(koT.oCheckDisk), findsOneWidget);
    expect(find.text(koT.oActDisk), findsOneWidget, reason: 'a red item must say what to do');
    expect(find.text(koT.oActBackup), findsOneWidget, reason: 'missing backup is red too');
    expect(find.text(koT.oActDb), findsNothing, reason: 'green items carry no action line');
    expect(find.text(koT.oActIntegration), findsOneWidget, reason: 'failing Solapi says what to do');
    await unmount(tester);
  });

  testWidgets('saving alert switches and quiet hours sends them to the owner endpoint', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/ops/status', _status(level: 'green'))
      ..reply('GET', '/admin/ops/alerts', _alerts)
      ..reply('GET', '/admin/config', _config)
      ..reply('GET', '/admin/client-errors', _errors)
      ..reply('PUT', '/admin/ops/alerts', {'prefs': {}});
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const OpsScreen());
    await settle(tester);

    final sms = find.widgetWithText(SwitchListTile, koT.oRuleSms);
    await tester.scrollUntilVisible(sms, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(sms);
    await settle(tester, duration: const Duration(milliseconds: 200));

    // The alerts card comes first; the flags card has its own save button further down.
    final save = find.widgetWithText(PrimaryButton, koT.oSave).first;
    await tester.scrollUntilVisible(save, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(save);
    await settle(tester);

    final sent = fake.lastCall('PUT', '/admin/ops/alerts')!.json;
    expect((sent['rules'] as Map)['sms_failing'], isFalse);
    expect(sent['quiet_start'], 22);
    expect(sent['quiet_end'], 7);
    await unmount(tester);
  });

  testWidgets('a consultant sees the status but cannot change alert settings', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/ops/status', _status(level: 'green'))
      ..reply('GET', '/admin/ops/alerts', _alerts)
      ..reply('GET', '/admin/config', _config)
      ..reply('GET', '/admin/client-errors', _errors);
    final env = await TestEnv.create(fake: fake, role: 'staff_consultant');
    await pumpConsoleScreen(tester, env, const OpsScreen());
    await settle(tester);

    expect(find.widgetWithText(PrimaryButton, koT.oSave), findsNothing);
    expect(find.text(koT.oCheckDisk), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('background jobs show each last success, and a stalled one says so', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()
      ..reply('GET', '/admin/ops/status', _status(level: 'red'))
      ..reply('GET', '/admin/ops/alerts', _alerts)
      ..reply('GET', '/admin/config', _config)
      ..reply('GET', '/admin/client-errors', _errors);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const OpsScreen());
    await settle(tester);

    final outbox = find.text(koT.oJob_notify_outbox);
    await tester.scrollUntilVisible(outbox, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(koT.oJobs), findsOneWidget);
    expect(find.text(koT.oJob_reconciler), findsOneWidget);
    expect(find.textContaining(koT.oJobLastOk('').trim()), findsOneWidget, reason: 'the reconciler ran');
    expect(find.text(koT.oJobNever), findsOneWidget);
    expect(find.text(koT.oJobStalled), findsOneWidget);
    expect(find.text(koT.oJobErrors('3')), findsOneWidget);
    await unmount(tester);
  });
}
