import 'package:core/core.dart';
import 'package:customer/screens/reviews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

const _body = '다음에도 부를게요';
const _otherBody = '꼼꼼하게 해 주셨어요';
const _tallPhone = Size(390, 2600);

Json _review(String bookingId, int rating, String body) => {
  'booking_id': bookingId,
  'rating': rating,
  'body': body,
  'name': '김*수',
};

final _rows = [_review('bk-1', 5, _body), _review('bk-2', 4, _otherBody)];

void main() {
  testWidgets('a review shows its rating as star icons, not as text stars', (tester) async {
    final env = await TestEnv.create(signedIn: false);
    await pumpCustomerScreen(
      tester,
      env,
      Scaffold(body: ReviewTile(api: env.api, row: _rows.first)),
    );
    await settle(tester);

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    expect(find.textContaining('★'), findsNothing);
    expect(find.text(_body), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('report sits in the review overflow menu and opens the report form', (tester) async {
    final env = await TestEnv.create(signedIn: false);
    await pumpCustomerScreen(
      tester,
      env,
      Scaffold(body: ReviewTile(api: env.api, row: _rows.first)),
    );
    await settle(tester);

    // No loud report link on the card itself.
    expect(find.text(koT.reportAction), findsNothing);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tester.tap(find.text(koT.reportAction));
    await settle(tester);

    expect(find.text(koT.reportSheetTitle), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('후기 전체 보기 lists every review from the public list', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi()..reply('GET', '/public/reviews', _rows);
    final env = await TestEnv.create(fake: fake, signedIn: false);
    await pumpCustomerScreen(tester, env, const ReviewsAllScreen());
    await settle(tester);

    expect(find.text(_body), findsOneWidget);
    expect(find.text(_otherBody), findsOneWidget);
    expect(find.text(koT.reviewsEmpty), findsNothing);
    await unmount(tester);
  });

  testWidgets('the full list says so when there are no reviews yet', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi()..reply('GET', '/public/reviews', const <Json>[]);
    final env = await TestEnv.create(fake: fake, signedIn: false);
    await pumpCustomerScreen(tester, env, const ReviewsAllScreen());
    await settle(tester);

    expect(find.text(koT.reviewsEmpty), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('PICK fills with popular services and the newest reviews, and opens the full list', (tester) async {
    setViewport(tester, _tallPhone);
    final fake = FakeApi()..reply('GET', '/public/reviews', _rows);
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.dhHomePick(BrandConfig.placeholder.name)));
    await tester.tap(find.text(koT.dhHomePick(BrandConfig.placeholder.name)));
    await settle(tester);

    expect(find.text(koT.popularServices), findsOneWidget);
    expect(find.text(koT.service('studio')), findsWidgets);
    expect(find.text(_body), findsOneWidget);
    await tester.tap(find.text(koT.reviewsSeeAll));
    await settle(tester);
    expect(find.byType(ReviewsAllScreen), findsOneWidget);
    await unmount(tester);
  });
}
