import 'package:console/screens/platform.dart';
import 'package:console/screens/setup.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';

const _config = <String, Object?>{
  'flags': {'booking': true, 'chat': true, 'ai': true, 'payments': true},
  'maintenance': {'on': false, 'message': ''},
};

const _errors = <String, Object?>{
  'items': [
    {
      'id': 7,
      'at': '2026-11-11T03:15:00Z',
      'app': 'web',
      'version': '1.4.2',
      'message': 'Null check operator used on a null value',
      'stack': '#0 PartnerHome.build (package:partner/home.dart:42)',
    },
  ],
};

Widget _scrolled(Widget child) => SingleChildScrollView(child: child);

void main() {
  testWidgets('turning booking and maintenance on saves the whole config document', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()..reply('PUT', '/admin/config', _config);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(
      tester,
      env,
      _scrolled(FlagsCard(initial: _config, onSaved: () {})),
    );
    await settle(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, koT.oFlagBooking));
    await tester.tap(find.widgetWithText(SwitchListTile, koT.oMaintenance));
    await tester.enterText(find.byType(TextField), '  점검 중  ');
    await settle(tester, duration: const Duration(milliseconds: 200));

    await tester.tap(find.widgetWithText(PrimaryButton, koT.oSave));
    await settle(tester);

    final sent = fake.lastCall('PUT', '/admin/config')!.json as Map;
    expect((sent['flags'] as Map)['booking'], isFalse);
    expect((sent['flags'] as Map)['chat'], isTrue, reason: 'untouched flags keep their value');
    expect(sent['maintenance'], {'on': true, 'message': '점검 중'});
    await unmount(tester);
  });

  testWidgets('a consultant can read the switches but has no save button', (tester) async {
    setViewport(tester, wideSize);
    final env = await TestEnv.create(fake: FakeApi(), role: 'staff_consultant');
    await pumpConsoleScreen(
      tester,
      env,
      _scrolled(FlagsCard(initial: _config, onSaved: () {})),
    );
    await settle(tester);

    expect(find.text(koT.oFlagAi), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, koT.oSave), findsNothing);
    await unmount(tester);
  });

  testWidgets('client error reports show app, version and message, stack on expand', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()..reply('GET', '/admin/client-errors', _errors);
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, _scrolled(const ClientErrorsCard()));
    await settle(tester);

    expect(find.text('Null check operator used on a null value'), findsOneWidget);
    expect(find.textContaining('web · 1.4.2'), findsOneWidget);
    expect(find.text(koT.oClientErrorsEmpty), findsNothing);
    expect(fake.lastCall('GET', '/admin/client-errors')!.query['limit'], '50');
    await unmount(tester);
  });

  testWidgets('no reports shows the empty line', (tester) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()..reply('GET', '/admin/client-errors', {'items': <Object?>[]});
    final env = await TestEnv.create(fake: fake, role: 'staff_admin');
    await pumpConsoleScreen(tester, env, _scrolled(const ClientErrorsCard()));
    await settle(tester);

    expect(find.text(koT.oClientErrorsEmpty), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('heartbeat card says what to do when the ping URL is not set', (tester) async {
    setViewport(tester, wideSize);
    final env = await TestEnv.create(fake: FakeApi(), role: 'staff_admin');
    await pumpConsoleScreen(tester, env, const HeartbeatCard(configured: false));
    await settle(tester);

    expect(find.text(koT.oHeartbeatOff), findsOneWidget);
    expect(find.text(koT.oHeartbeatOn), findsNothing);
    await unmount(tester);
  });
}
