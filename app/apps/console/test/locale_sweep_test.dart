import 'package:console/screens/bookings.dart';
import 'package:console/screens/catalog.dart';
import 'package:console/screens/dashboard.dart';
import 'package:console/screens/finance.dart';
import 'package:console/screens/first_run.dart';
import 'package:console/screens/growth.dart';
import 'package:console/screens/inbox.dart';
import 'package:console/screens/marketing.dart';
import 'package:console/screens/ops.dart';
import 'package:console/screens/people.dart';
import 'package:console/screens/setup.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

/// Every console language at the two sizes the console ships on: a small Android phone with
/// large system text (the worst case for long translations), and a Windows desktop window.
/// Any RenderFlex overflow or exception fails the test.
const _phone = Size(360, 640);
const _phoneText = 1.3;
const _desktop = Size(1280, 800);

Json _card(String code, List<Json> fields) => {
  'code': code,
  'source': 'none',
  'configured': false,
  'fields': fields,
  'last_test': null,
};

Json _field(String name, String kind, {bool required = false}) => {
  'name': name,
  'kind': kind,
  'required': required,
  'set': false,
  'preview': null,
};

/// Setup wizard cards, one per integration section, with the fields the server sends.
List<Json> _setupCards() => [
  _card('portone', [_field('store_id', 'text', required: true), _field('api_secret', 'secret', required: true), _field('webhook_secret', 'secret'), _field('channel_keys', 'map')]),
  _card('solapi', [_field('api_key', 'secret', required: true), _field('api_secret', 'secret', required: true), _field('sender', 'text', required: true), _field('pf_id', 'text'), _field('templates', 'map')]),
  _card('push', [_field('service_account', 'file', required: true)]),
  _card('kakao', [_field('app_id', 'text', required: true)]),
  _card('naver', [_field('client_id', 'text', required: true)]),
  _card('google', [_field('client_ids', 'list', required: true)]),
  _card('apple', [_field('client_ids', 'list', required: true)]),
  _card('ai', [_field('api_key', 'secret', required: true), _field('model', 'text'), _field('mode', 'text'), _field('thread_hourly_cap', 'text'), _field('member_daily_cap', 'text'), _field('daily_cap', 'text')]),
  _card('backup', [_field('endpoint', 'text', required: true), _field('region', 'text', required: true), _field('bucket', 'text', required: true), _field('access_key', 'secret', required: true), _field('secret_key', 'secret', required: true), _field('retention_days', 'text')]),
];

Json _ops() => {
  'level': 'red',
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
    {'code': 'solapi', 'configured': true, 'level': 'red', 'last_ok_at': null, 'last_fail_at': '2026-11-11T01:00:00Z', 'last_error': 'provider_error'},
    {'code': 'portone', 'configured': false, 'level': 'yellow', 'last_ok_at': null, 'last_fail_at': null, 'last_error': null},
  ],
};

const _alerts = <String, Object?>{
  'prefs': {'rules': {'sms_failing': true}, 'quiet_start': 22, 'quiet_end': 7, 'alert_phone': null},
  'rules': ['sms_failing', 'disk_low'],
  'default_phone': '021234567',
  'cooldown_hours': 6,
};

FakeApi _stockedApi() {
  final fake = FakeApi()
    ..reply('GET', '/admin/bookings/bk-1', bookingDetail(status: 2))
    ..reply('GET', '/admin/bookings/bk-1/quotes', const <Json>[])
    ..reply('GET', '/admin/threads', [threadJson(id: 'th-1', unreadMember: 3, lastMessage: {'kind': 'text', 'body': {'text': 'Xin chào! Chúng tôi sẽ đến lúc 9 giờ sáng.'}, 'sender': 'customer'})])
    ..reply('GET', '/admin/threads/th-1/messages', const <Json>[])
    ..reply('GET', '/admin/ai/usage', {'calls': 12, 'answered': 10, 'input_tokens': 5000, 'output_tokens': 900, 'cache_read_tokens': 0, 'cache_write_tokens': 0})
    ..reply('GET', '/admin/pros', const <Json>[])
    ..reply('GET', '/admin/settlements', const <Json>[])
    ..reply('GET', '/admin/customers', const <Json>[])
    ..reply('GET', '/admin/staff', const <Json>[])
    ..reply('GET', '/admin/growth', {'welcome': {}, 'referral': {}})
    ..reply('GET', '/admin/reviews', const <Json>[])
    ..reply('GET', '/admin/slot-capacity', const <Json>[])
    ..reply('GET', '/admin/quote-formula', {})
    ..reply('GET', '/admin/payment-methods', const <Json>[])
    ..reply('GET', '/admin/setup', {
      'business': {'name': 'Malkkeum Cleaning'},
      'review_account': null,
      'integrations': _setupCards(),
      'dev_mode': false,
      'public_base_url': 'https://example.test',
      'webhook_url': 'https://example.test/v1/webhooks/portone',
    })
    ..reply('GET', '/admin/ops/status', _ops())
    ..reply('GET', '/admin/ops/alerts', _alerts)
    ..reply('GET', '/setup', {'needs_admin': false});
  stockConsoleApi(fake, bookings: [
    bookingJson(id: 'bk-1', number: 'B-20260101-0001', status: 2, estimate: 420000),
    bookingJson(id: 'bk-2', number: 'B-20260101-0002', serviceCode: 'move_out', status: 0),
  ]);
  return fake;
}

/// One screen at one size and language. Failures are collected so one run lists every broken screen.
Future<void> _pumpAndCheck(WidgetTester tester, TestEnv env, Widget screen, String name, List<String> failures) async {
  // Capture layout errors with their widget details (the test binding keeps only the bare message).
  final saved = FlutterError.onError;
  final errors = <FlutterErrorDetails>[];
  FlutterError.onError = errors.add;
  try {
    await pumpConsoleScreen(tester, env, screen);
    await settle(tester, duration: const Duration(milliseconds: 600));
  } finally {
    FlutterError.onError = saved;
  }
  for (final d in errors) {
    final where = RegExp(r'file:///[^\s)]+/(?:console/lib|ui/lib)/[^\s)]+').allMatches(d.toString()).map((m) => m.group(0)).toSet();
    failures.add('$name: ${d.exceptionAsString().split('\n').first} @ ${where.take(3).join(' ')}');
  }
  await unmount(tester);
}

final _screens = <(String, Widget)>[
  ('dashboard', const DashboardScreen()),
  ('bookings', const BookingsScreen()),
  ('quote desk', const BookingsScreen(quoteDesk: true)),
  ('inbox', const InboxScreen()),
  ('catalog', const CatalogScreen()),
  ('marketing', const MarketingScreen()),
  ('partners', const PartnersScreen()),
  ('settlements', const SettlementsScreen()),
  ('finance', const FinanceScreen()),
  ('customers', const CustomersScreen()),
  ('staff', const StaffScreen()),
  ('setup (business, pay methods, review, AI and every integration card)', const SetupScreen()),
  ('growth', const GrowthSettings()),
  ('ops', const OpsScreen()),
  ('first run', const FirstRunScreen()),
];

void main() {
  for (final locale in LocaleController.supported) {
    final code = locale.languageCode;

    testWidgets('[$code] every console screen fits a small phone with large text', (tester) async {
      setViewport(tester, _phone);
      tester.platformDispatcher.textScaleFactorTestValue = _phoneText;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final env = await TestEnv.create(fake: _stockedApi(), localeCode: code, role: 'staff_admin');
      final failures = <String>[];
      for (final (name, screen) in _screens) {
        await _pumpAndCheck(tester, env, screen, name, failures);
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('[$code] every console screen fits a desktop window', (tester) async {
      setViewport(tester, _desktop);
      final env = await TestEnv.create(fake: _stockedApi(), localeCode: code, role: 'staff_admin');
      final failures = <String>[];
      for (final (name, screen) in _screens) {
        await _pumpAndCheck(tester, env, screen, name, failures);
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('[$code] the app shell and sign-in fit a small phone with large text', (tester) async {
      setViewport(tester, _phone);
      tester.platformDispatcher.textScaleFactorTestValue = _phoneText;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final signedIn = await TestEnv.create(fake: _stockedApi(), localeCode: code, role: 'staff_admin');
      await pumpConsoleApp(tester, signedIn);
      await settle(tester, duration: const Duration(milliseconds: 600));
      final failures = <String>[];
      final shellErr = tester.takeException();
      if (shellErr != null) failures.add('shell: $shellErr');
      await unmount(tester);

      final signedOut = await TestEnv.create(fake: _stockedApi(), localeCode: code, signedIn: false);
      await pumpConsoleApp(tester, signedOut);
      await settle(tester, duration: const Duration(milliseconds: 600));
      final signInErr = tester.takeException();
      if (signInErr != null) failures.add('sign-in: $signInErr');
      await unmount(tester);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('[$code] the app shell fits a desktop window', (tester) async {
      setViewport(tester, _desktop);
      final env = await TestEnv.create(fake: _stockedApi(), localeCode: code, role: 'staff_admin');
      await pumpConsoleApp(tester, env);
      await settle(tester, duration: const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull, reason: 'shell');
      await unmount(tester);
    });
  }
}
