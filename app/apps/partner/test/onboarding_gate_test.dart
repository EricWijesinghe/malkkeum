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
