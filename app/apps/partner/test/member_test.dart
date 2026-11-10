import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/member.dart';
import 'package:test_support/test_support.dart';

import 'support/partner_host.dart';

void main() {
  testWidgets('team member sees only assigned jobs and opens one with address and memo', (tester) async {
    setViewport(tester, phoneSize);
    final visit = DateTime.now().add(const Duration(days: 2));
    final job = bookingJson(id: 'bk-7', serviceCode: 'bathroom', status: 2, visitDate: visit);
    final fake = FakeApi()
      ..reply('GET', '/member/me', {'id': 'm1', 'name': '민수', 'team_id': 'p1', 'team_name': '반짝팀'})
      ..reply('GET', '/member/jobs', [job])
      ..onGet('/member/jobs/bk-7', (_) => {'booking': job, 'customer_name': '김*수', 'team_memo': '현관 비밀번호 1234'});
    final env = await TestEnv.create(fake: fake, role: 'member');
    await pumpPartnerScreen(tester, env, const MemberShell());
    await pumpUntilFound(tester, find.text(koT.service('bathroom')));

    expect(find.text(koT.mTeam('반짝팀')), findsOneWidget);
    expect(fake.calls.where((c) => c.path.startsWith('/partner')), isEmpty, reason: 'members never call owner endpoints');

    await tester.tap(find.text(koT.service('bathroom')));
    await pumpUntilFound(tester, find.text('현관 비밀번호 1234'));
    expect(find.text(koT.pComplete), findsOneWidget, reason: 'assigned job can be completed');
    await unmount(tester);
  });
}
