import 'dart:io';

import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/pick.dart';
import 'package:customer/screens/reviews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';

const _fiveServices = ['studio', 'kitchen', 'bathroom', 'mattress', 'aircon'];

Service _fixed(String code, int price) =>
    Service(code: code, type: PricingType.fixed, price: price);

void main() {
  testWidgets('date pickers resolve Hangul through system fallback faces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) =>
              koreanPickerBuilder(ctx, const SizedBox(key: ValueKey('probe'))),
        ),
      ),
    );

    final theme = Theme.of(tester.element(find.byKey(const ValueKey('probe'))));
    final fallback =
        theme.textTheme.bodyMedium?.fontFamilyFallback ?? const <String>[];
    expect(fallback, containsAll(['Noto Sans KR', 'Malgun Gothic']));
  });

  test(
    'the web splash is dismissed by the app ready event only, with a timeout',
    () {
      final html = File('web/index.html').readAsStringSync();

      expect(html, contains("addEventListener('dahae-ready'"));
      expect(html, isNot(contains('flutter-first-frame')));
      expect(html, contains('setTimeout(hide, 12000)'));
      expect(html, contains('pointer-events: none'));
    },
  );

  test('the web build preloads the Medium weight the first screens use', () {
    final html = File('web/index.html').readAsStringSync();

    expect(html, contains('DahaeSans-Medium.otf'));
  });

  testWidgets('PICK shows at most four services, each with its price line', (
    tester,
  ) async {
    final services = [for (final code in _fiveServices) _fixed(code, 30000)];
    final env = await TestEnv.create(signedIn: false);
    await pumpCustomerScreen(
      tester,
      env,
      Scaffold(body: PopularServices(services: services)),
    );
    await settle(tester);

    for (final code in _fiveServices.take(4)) {
      expect(find.text(koT.service(code)), findsOneWidget);
    }
    expect(find.text(koT.service('aircon')), findsNothing);
    expect(find.textContaining(koT.fromPrice('')), findsNWidgets(4));
    await unmount(tester);
  });

  testWidgets('PICK shows no popular section when the catalogue is empty', (
    tester,
  ) async {
    final env = await TestEnv.create(signedIn: false);
    await pumpCustomerScreen(
      tester,
      env,
      const Scaffold(body: PopularServices(services: [])),
    );
    await settle(tester);

    expect(find.text(koT.popularServices), findsNothing);
    await unmount(tester);
  });

  testWidgets('recent reviews stay hidden when the review list fails to load', (
    tester,
  ) async {
    final fake = FakeApi()..reply('GET', '/public/reviews', null, status: 500);
    final env = await TestEnv.create(fake: fake, signedIn: false);
    await pumpCustomerScreen(
      tester,
      env,
      const Scaffold(body: SingleChildScrollView(child: RecentReviews())),
    );
    await settle(tester);

    expect(find.text(koT.proofReviewsTitle), findsNothing);
    expect(find.text(koT.reviewsSeeAll), findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
