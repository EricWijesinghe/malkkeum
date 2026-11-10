import 'package:core/core.dart';
import 'package:customer/screens/growth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Json _proof({Object? homes = 12, Object? rating = 4.7, Object? count = 12, List<Json>? reviews}) => {
  'homes_this_month': homes,
  'rating': rating,
  'review_count': count,
  'reviews': reviews ?? [{'rating': 5, 'body': '꼼꼼해요', 'name': '김*수'}],
};

void main() {
  testWidgets('review sheet: stars are required, then text and the rating go to the booking', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('POST', '/bookings/bk-1/review', {'ok': true});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(
      tester,
      env,
      Builder(
        builder: (context) => Center(
          child: FilledButton(onPressed: () => showReviewSheet(context, 'bk-1'), child: const Text('open')),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await settle(tester);
    final submit = find.widgetWithText(FilledButton, koT.reviewSubmit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull, reason: 'no rating yet');

    await tester.tap(find.byTooltip(koT.ratingStars('4')));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '  꼼꼼하고 친절했어요  ');
    await settle(tester);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await settle(tester);

    final sent = fake.lastCall('POST', '/bookings/bk-1/review');
    expect(sent, isNotNull);
    expect(sent!.body, {'rating': 4, 'body': '꼼꼼하고 친절했어요', 'photos': <String>[]});
    expect(find.byType(ReviewSheet), findsNothing, reason: 'closes after saving');
    await unmount(tester);
  });

  testWidgets('social proof shows real numbers and masked reviews', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('GET', '/public/proof', _proof());
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const Scaffold(body: SocialProofCard()));
    await pumpUntilFound(tester, find.text(koT.proofHomes('12')));
    expect(find.text(koT.proofRating('4.7', '12')), findsOneWidget);
    expect(find.textContaining('김*수'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('social proof stays hidden while every count is too small to show', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('GET', '/public/proof', _proof(homes: null, rating: null, count: null, reviews: const []));
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const Scaffold(body: SocialProofCard()));
    await settle(tester);
    expect(fake.lastCall('GET', '/public/proof'), isNotNull, reason: 'it did ask');
    expect(find.text(koT.proofReviewsTitle), findsNothing);
    expect(find.textContaining('이번 달'), findsNothing);
    await unmount(tester);
  });
}
