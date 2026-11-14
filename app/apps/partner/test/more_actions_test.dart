import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:partner/screens/more.dart';
import 'package:test_support/test_support.dart';

import 'support/partner_host.dart';

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'Partner',
      packageName: 'kr.example.partner',
      version: '9.8.7',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  testWidgets('the version row shows the installed build version', (
    tester,
  ) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'pro');
    await pumpPartnerScreen(tester, env, const MoreTab());
    await pumpUntilFound(tester, find.text(koT.moreVersion('9.8.7')));
  });

  testWidgets('signing out asks first; cancelling keeps the user signed in', (
    tester,
  ) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'pro');
    await pumpPartnerScreen(tester, env, const MoreTab());
    await pumpUntilFound(tester, find.text(koT.logout));

    await tester.ensureVisible(find.text(koT.logout));
    await tester.tap(find.text(koT.logout));
    await settle(tester);
    expect(find.text(koT.pLogoutConfirm), findsOneWidget);

    await tester.tap(find.text(koT.cancel));
    await settle(tester);
    expect(find.text(koT.pLogoutConfirm), findsNothing);
    expect(fake.lastCall('POST', '/auth/logout'), isNull);
  });

  testWidgets('review rows have no reply button until replies ship', (
    tester,
  ) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('GET', '/partner/reviews', [
        {
          'booking_id': 'b-1',
          'rating': 5,
          'body': '깔끔해요',
          'service_code': 'studio',
        },
      ]);
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'pro');
    await pumpPartnerScreen(tester, env, const ReviewsScreen());
    await pumpUntilFound(tester, find.text('깔끔해요'));

    expect(find.text(koT.pReplyLater), findsNothing);
  });
}
