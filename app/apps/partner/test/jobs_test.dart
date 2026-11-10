import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/jobs.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/partner_host.dart';

/// Job detail as the detail screen reads it: not yet committed, direct (not quote) job.
Json _jobDetail({String id = 'job-1', int status = 1, bool committed = false}) => {
      'booking': {
        'id': id,
        'number': 'B-20260101-0002',
        'service_code': 'studio',
        'is_quote': false,
        'status': status,
        'estimate': 45000,
        'size_pyeong': 20,
        'visit_date': isoDay(DateTime.now().add(const Duration(days: 2))),
        'start_hour': 9,
        'minutes': 120,
        'district_code': '11680',
        'road_area': null,
        'address': {'road_address': '서울특별시 강남구 테헤란로 1', 'detail': '101동'},
        'visit_notes': <String, dynamic>{},
        'answers': null,
        'reschedule': null,
        'cancelled': false,
      },
      'committed': committed,
      'payout': null,
    };

void main() {
  testWidgets('the feed defaults to direct jobs and the quote segment asks for quote requests', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const JobsTab());
    await pumpUntilFound(tester, find.text(koT.pDirect));

    final first = fake.lastCall('GET', '/partner/jobs')!;
    expect(first.query['kind'], 'direct');
    expect(first.query['include_closed'], 'false');
    expect(first.query['sort'], 'newest');

    await tester.tap(find.text(koT.pQuoteReq));
    await settle(tester);
    expect(fake.lastCall('GET', '/partner/jobs')!.query['kind'], 'quote');
    await unmount(tester);
  });

  testWidgets('a direct job card shows the pro payout after the platform fee', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    // 100,000 at a 20% fee leaves 80,000 for the pro.
    stockPartnerApi(fake, jobs: [jobJson(customerPrice: 100000)]);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const JobsTab());
    await pumpUntilFound(tester, find.text(koT.service('studio')));

    expect(find.text(koT.pPayout), findsOneWidget);
    expect(find.text(formatWon(80000, 'ko')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('accepting a job asks for confirmation, then posts accept and confirms', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..onGet('/partner/jobs/job-1', (_) => _jobDetail())
      ..reply('POST', '/partner/jobs/job-1/accept', {'ok': true});
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const JobDetailScreen(id: 'job-1'));
    await pumpUntilFound(tester, find.text(koT.pAccept));

    await tester.tap(find.text(koT.pAccept));
    await settle(tester);
    expect(find.text(koT.pAcceptConfirm), findsOneWidget);
    expect(fake.callsTo('POST', '/partner/jobs/job-1/accept'), isEmpty, reason: 'nothing sent before confirming');

    // The sheet's button is the topmost "accept" label.
    await tester.tap(find.text(koT.pAccept).last);
    await settle(tester);
    expect(fake.callsTo('POST', '/partner/jobs/job-1/accept'), hasLength(1));
    expect(find.text(koT.pAccepted), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('accepting a job someone else already took shows the already-taken message', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..onGet('/partner/jobs/job-1', (_) => _jobDetail())
      ..reply('POST', '/partner/jobs/job-1/accept', {'error': {'code': 'already_taken'}}, status: 409);
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const JobDetailScreen(id: 'job-1'));
    await pumpUntilFound(tester, find.text(koT.pAccept));

    await tester.tap(find.text(koT.pAccept));
    await settle(tester);
    await tester.tap(find.text(koT.pAccept).last);
    await settle(tester);

    expect(find.text(koT.err_already_taken), findsOneWidget);
    expect(find.text(koT.pAccepted), findsNothing);
    await unmount(tester);
  });
}
