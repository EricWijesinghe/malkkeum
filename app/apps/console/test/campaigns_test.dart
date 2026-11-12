import 'package:console/screens/analytics_view.dart';
import 'package:console/screens/campaigns.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

Widget testApp(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    T.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  group('campaign rules', () {
    test('segments serialise to the server shapes', () {
      expect(audienceJson(AudienceKind.all, 30), isEmpty);
      expect(audienceJson(AudienceKind.neverBooked, 30), [
        {'type': 'never_booked'},
      ]);
      expect(audienceJson(AudienceKind.lapsed, 45), [
        {'type': 'last_booking_older_than', 'days': 45},
      ]);
    });

    test('sms preview matches the server ad format', () {
      expect(smsAdText('이번 주 할인', '080-123-4567'), '(광고) 이번 주 할인\n무료수신거부 080-123-4567');
    });

    test('opt-out numbers are 9 to 12 digits with optional hyphens', () {
      expect(validOptout('080-123-4567'), isTrue);
      expect(validOptout('0801234567'), isTrue);
      expect(validOptout('080-12'), isFalse);
      expect(validOptout('080-abc-4567'), isFalse);
    });

    test('shareOf is 0 when there is nothing to divide by', () {
      expect(shareOf(3, 0), 0);
      expect(shareOf(1, 4), 0.25);
      expect(shareOf(9, 4), 1);
    });
  });

  testWidgets('builder shows consent count and blocks send until the form is valid', (tester) async {
    // Tall enough for the whole form: the send button sits below the default 600 px surface.
    setViewport(tester, const Size(800, 1600));
    final submitted = <Json>[];
    await tester.pumpWidget(testApp(
      CampaignBuilder(
        preview: (_) async => {'total': 10, 'consented': 4},
        submit: (body, at) async => submitted.add({...body, 'at': at?.toIso8601String()}),
        testSend: (_, _, _) async {},
      ),
    ));
    await tester.pumpAndSettle();
    final t = tester.element(find.byType(CampaignBuilder)).t;

    expect(find.text(t.cmConsentCount('10', '4')), findsOneWidget);
    final send = find.widgetWithText(FilledButton, t.cmSendNow);
    expect(tester.widget<FilledButton>(send).onPressed, isNull, reason: 'empty title and body');

    await tester.enterText(find.widgetWithText(TextField, t.cmTitle), '신규 혜택');
    await tester.enterText(find.widgetWithText(TextField, t.cmBody), '첫 청소 할인');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(send).onPressed, isNotNull);

    await tester.tap(find.text(t.cmSms).first);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(send).onPressed, isNull, reason: 'sms needs an opt-out number');
    expect(find.textContaining('(광고) 첫 청소 할인'), findsOneWidget, reason: 'preview shows the ad prefix');

    await tester.enterText(find.widgetWithText(TextField, t.cmOptout), '080-123-4567');
    await tester.pumpAndSettle();
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(submitted, hasLength(1));
    expect(submitted.single['channel'], 'sms');
    expect(submitted.single['optout_number'], '080-123-4567');
    expect(submitted.single['at'], isNull, reason: 'send now');
  });

  testWidgets('funnel and cohort views show stage counts and weekly rows', (tester) async {
    await tester.pumpWidget(testApp(
      AnalyticsView(
        funnel: (_) async => {
          'installs': 10,
          'signed_up': 8,
          'quoted': 4,
          'booked': 2,
          'paid': 2,
          'repeat_buyers': 1,
        },
        cohorts: (_) async => [
          {'week': '2026-11-02T00:00:00Z', 'size': 8, 'w1': 2, 'w2': 1, 'w3': 0, 'w4': 0},
        ],
      ),
    ));
    await tester.pumpAndSettle();
    final t = tester.element(find.byType(AnalyticsView)).t;

    expect(find.text('${t.anSignedUp} · 8'), findsOneWidget);
    expect(find.text('${t.anRepeat} · 1'), findsOneWidget);
    expect(find.text('2026-11-02'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });
}
