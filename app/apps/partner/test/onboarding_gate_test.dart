import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/partner_host.dart';

void main() {
  testWidgets('onboarding keeps "finish" disabled until name, team, a service and a district are set', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(
      fake,
      profile: verifiedProfile(name: '', status: 'pending'),
      prefs: {'services': <String>[], 'districts': <String>[]},
    );
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pOnbTitle));

    final done = find.widgetWithText(PrimaryButton, koT.pOnbDone);
    expect(tester.widget<PrimaryButton>(done).onPressed, isNull, reason: 'empty form');

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '김파트너');
    await settle(tester, duration: const Duration(milliseconds: 200));
    expect(tester.widget<PrimaryButton>(done).onPressed, isNull, reason: 'team still missing');

    await tester.enterText(fields.at(1), '말끔팀');
    await settle(tester, duration: const Duration(milliseconds: 200));
    expect(tester.widget<PrimaryButton>(done).onPressed, isNull, reason: 'no service yet');

    await tester.tap(find.text(koT.serviceShort('studio')));
    await settle(tester, duration: const Duration(milliseconds: 200));
    expect(tester.widget<PrimaryButton>(done).onPressed, isNull, reason: 'no district yet');

    await tester.tap(find.text(seoulDistricts.first.name('ko')));
    await settle(tester, duration: const Duration(milliseconds: 200));
    expect(tester.widget<PrimaryButton>(done).onPressed, isNotNull);
    await unmount(tester);
  });

  testWidgets('finishing onboarding saves the profile and prefs, then waits for approval', (tester) async {
    setViewport(tester, phoneSize);
    var me = verifiedProfile(name: '', status: 'pending');
    var prefs = <String, dynamic>{'services': <String>[], 'districts': <String>[]};
    final fake = FakeApi()
      ..onGet('/partner/me', (_) => me)
      ..onPatch('/partner/me', (c) {
        me = {...me, 'name': c.json['name'], 'team_name': c.json['team_name']};
        return me;
      })
      ..onGet('/partner/prefs', (_) => prefs)
      ..onPut('/partner/prefs', (c) {
        prefs = c.json;
        return prefs;
      })
      ..reply('GET', '/partner/threads', const <Json>[])
      ..reply('GET', '/partner/quotes', const <Json>[])
      ..reply('GET', '/partner/jobs', const <Json>[]);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pOnbTitle));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '김파트너');
    await tester.enterText(fields.at(1), '말끔팀');
    await tester.tap(find.text(koT.serviceShort('kitchen')));
    await tester.tap(find.text(seoulDistricts.first.name('ko')));
    await settle(tester, duration: const Duration(milliseconds: 200));
    await tester.tap(find.text(koT.pOnbDone));
    await settle(tester);

    expect(fake.lastCall('PATCH', '/partner/me')!.json['team_name'], '말끔팀');
    expect(fake.lastCall('PUT', '/partner/prefs')!.json['services'], ['kitchen']);
    expect(fake.lastCall('PUT', '/partner/prefs')!.json['districts'], [seoulDistricts.first.code]);
    await pumpUntilFound(tester, find.text(koT.pPendingTitle));
    await unmount(tester);
  });

  testWidgets('a verified, onboarded pro goes straight into the app shell', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerApp(tester, env);
    await settle(tester, duration: const Duration(seconds: 1));
    expect(find.text(koT.pPendingTitle), findsNothing);
    expect(find.text(koT.pOnbTitle), findsNothing);
    await unmount(tester);
  });

  testWidgets('a pending pro sees the waiting screen, not the jobs', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake, profile: verifiedProfile(status: 'pending'));
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pPendingTitle));
    expect(find.text(koT.pPayoutAccount), findsOneWidget);
    expect(find.text(koT.pTabJobs), findsNothing);
    await unmount(tester);
  });

  testWidgets('no signal at start: retry runs the boot again and never signs the pro out', (tester) async {
    setViewport(tester, phoneSize);
    var online = false;
    final env = await TestEnv.create(fake: _flakyApi(() => online), role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.byType(ErrorRetry));
    expect(find.text(koT.errorNetwork), findsOneWidget);
    expect(find.text(koT.logout), findsOneWidget, reason: 'signing out is a separate, quieter button');

    await tester.tap(find.text(koT.retry));
    await settle(tester, duration: const Duration(seconds: 1));
    expect(env.session.signedIn, isTrue, reason: 'retry is not sign-out');
    expect(env.fake.callsTo('GET', '/partner/me'), hasLength(2), reason: 'the boot ran again');
    expect(find.byType(ErrorRetry), findsOneWidget);

    online = true;
    await tester.tap(find.text(koT.retry));
    await pumpUntilFound(tester, find.text(koT.pTabJobs));
    expect(env.session.signedIn, isTrue);
    await unmount(tester);
  });

  testWidgets('no signal at start: a pro verified last time still opens the app from the saved profile', (tester) async {
    setViewport(tester, phoneSize);
    var online = true;
    final env = await TestEnv.create(fake: _flakyApi(() => online), role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pTabJobs));
    await unmount(tester);

    online = false;
    final app = await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pTabJobs));
    expect(app.status, 'verified');
    expect(app.name, '말끔팀');
    expect(env.session.signedIn, isTrue);

    // No timer polls while offline: the realtime socket's reconnect (or an app resume) is the cue.
    final asked = env.fake.callsTo('GET', '/partner/me').length;
    await settle(tester, duration: const Duration(seconds: 25));
    expect(env.fake.callsTo('GET', '/partner/me'), hasLength(asked));

    // Signal returns: the socket reconnects and sends resync; the app catches up (real profile, then the queue).
    online = true;
    (app.realtime as FakeRealtime).emit({'type': 'resync'});
    await settle(tester, duration: const Duration(seconds: 1));
    expect(env.fake.callsTo('GET', '/partner/me'), hasLength(asked + 1));
    expect(app.status, 'verified');
    await unmount(tester);
  });

  testWidgets('signing out forgets the saved profile, so the next start without signal asks to retry', (tester) async {
    setViewport(tester, phoneSize);
    var online = true;
    final env = await TestEnv.create(fake: _flakyApi(() => online), role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pTabJobs));
    await env.session.logout();
    await unmount(tester);

    online = false;
    await env.session.save({'access_token': 'a-2', 'refresh_token': 'r-2', 'role': 'partner', 'subject': 'user-1'});
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.byType(ErrorRetry));
    expect(find.text(koT.pTabJobs), findsNothing);
    await unmount(tester);
  });

  testWidgets('a server refusal at start is never papered over with the saved profile', (tester) async {
    setViewport(tester, phoneSize);
    var refuse = false;
    final fake = FakeApi()..onGet('/partner/me', (_) => refuse ? const ApiReply(500, {'error': {'code': 'internal'}}) : verifiedProfile());
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pTabJobs));
    await unmount(tester);

    refuse = true;
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.byType(ErrorRetry));
    expect(find.text(koT.pTabJobs), findsNothing);
    await unmount(tester);
  });

  testWidgets('a suspended pro is blocked with the suspension notice', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake, profile: verifiedProfile(status: 'suspended'));
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.pSuspended));
    await unmount(tester);
  });
}

/// The start-up endpoints of a verified pro; every call fails like a dead connection while [online] is false.
FakeApi _flakyApi(bool Function() online) {
  Object? up(Object? body) {
    if (!online()) throw const SocketException('no signal');
    return body;
  }

  return FakeApi()
    ..onGet('/partner/me', (_) => up(verifiedProfile()))
    ..onGet('/partner/prefs', (_) => up({'services': ['studio'], 'districts': ['11680']}))
    ..onGet('/partner/threads', (_) => up(const <Json>[]))
    ..onGet('/partner/quotes', (_) => up(const <Json>[]))
    ..onGet('/partner/jobs', (_) => up(const <Json>[]));
}
