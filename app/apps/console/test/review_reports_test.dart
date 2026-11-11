import 'package:console/screens/review_reports.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget testApp(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    T.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: ListView(children: [child])),
);

Json _review({bool blocked = false}) => {
  'booking_id': 'b1',
  'rating': 2,
  'body': '나쁜 내용',
  'customer_name': '김*수',
  'pro_name': '청소팀',
  'hidden': true,
  'author_blocked': blocked,
  'reports': [
    {'reason': 'spam', 'note': ''},
    {'reason': 'personal_info', 'note': '전화번호 포함'},
  ],
};

void main() {
  testWidgets('queue lists reports and sends keep, hide, and author-block decisions', (tester) async {
    final decisions = <String>[];
    final blocks = <bool>[];
    await tester.pumpWidget(testApp(
      ReviewReportQueue(
        fetch: () async => [_review()],
        decide: (id, action) async => decisions.add('$id:$action'),
        setAuthorBlocked: (id, blocked) async => blocks.add(blocked),
      ),
    ));
    await tester.pumpAndSettle();
    final t = tester.element(find.byType(ReviewReportQueue)).t;

    expect(find.text(t.modReports('2')), findsOneWidget);
    expect(find.text(t.modHidden), findsOneWidget);
    expect(find.textContaining('전화번호 포함'), findsOneWidget);

    await tester.tap(find.text(t.modKeep));
    await tester.pumpAndSettle();
    expect(decisions, ['b1:keep']);

    await tester.tap(find.text(t.modBlockAuthor));
    await tester.pumpAndSettle();
    expect(blocks, [true]);
  });

  testWidgets('an empty queue says so', (tester) async {
    await tester.pumpWidget(testApp(
      ReviewReportQueue(
        fetch: () async => const [],
        decide: (_, _) async {},
        setAuthorBlocked: (_, _) async {},
      ),
    ));
    await tester.pumpAndSettle();
    final t = tester.element(find.byType(ReviewReportQueue)).t;
    expect(find.text(t.modEmpty), findsOneWidget);
  });
}
