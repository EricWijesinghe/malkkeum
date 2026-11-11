import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/site_actions.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/partner_host.dart';

/// Booking JSON as `GET /partner/jobs/{id}` returns it, for a job assigned to this partner.
Map<String, dynamic> _job({required DateTime visit, String? checkedInAt, bool entryCodeSet = true}) => {
      'id': 'job-1',
      'number': 'B-20260101-0003',
      'service_code': 'studio',
      'status': 2,
      'visit_date': isoDay(visit),
      'start_hour': 9,
      'entry_code_set': entryCodeSet,
      'checked_in_at': checkedInAt,
      'checked_out_at': null,
      'emergency': [
        {'label': 'police_fire_emergency', 'number': '112'},
        {'label': 'fire_rescue', 'number': '119'},
        {'label': 'shop', 'number': '021234567'},
      ],
    };

Widget _card(Map<String, dynamic> raw) => Scaffold(
      body: SingleChildScrollView(child: SiteActionsCard(raw: raw, act: (fn, done) async {})),
    );

void main() {
  testWidgets('on the visit day an assigned partner can check in, and the entry code is offered', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, _card(_job(visit: DateTime.now())));
    await pumpUntilFound(tester, find.text(koT.checkInAction));
    expect(find.text(koT.checkOutAction), findsNothing, reason: 'not arrived yet');
    expect(find.text(koT.entryCodeAction), findsOneWidget);
    expect(find.text('112'), findsOneWidget, reason: 'emergency numbers always shown');
    await unmount(tester);
  });

  testWidgets('after arrival the partner checks out, and check-in is gone', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, _card(_job(visit: DateTime.now(), checkedInAt: DateTime.now().toUtc().toIso8601String())));
    await pumpUntilFound(tester, find.text(koT.checkOutAction));
    expect(find.text(koT.checkInAction), findsNothing);
    await unmount(tester);
  });

  testWidgets('the entry code is not offered on another day', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, _card(_job(visit: DateTime.now().add(const Duration(days: 2)))));
    await pumpUntilFound(tester, find.text(koT.entryCodeNotToday));
    expect(find.text(koT.checkInAction), findsNothing, reason: 'check-in is visit-day only');
    await unmount(tester);
  });
}
