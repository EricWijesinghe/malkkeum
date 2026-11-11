import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
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
  testWidgets('submit stays disabled until a reason is picked, then sends reason and note', (tester) async {
    String? sentReason;
    String? sentNote;
    await tester.pumpWidget(_host(ReviewReportSheet(
      bookingId: 'b1',
      submit: (reason, note) async {
        sentReason = reason;
        sentNote = note;
      },
    )));
    final t = tester.element(find.byType(ReviewReportSheet)).t;
    FilledButton submit() => tester.widget<FilledButton>(find.byType(FilledButton));

    expect(submit().onPressed, isNull, reason: 'no reason yet');
    await tester.tap(find.text(reviewReportLabel(t, 'personal_info')));
    await tester.pump();
    expect(submit().onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), '  전화번호가 있어요  ');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(sentReason, 'personal_info');
    expect(sentNote, '전화번호가 있어요', reason: 'note is trimmed');
  });

  testWidgets('a duplicate report shows the already-reported message and keeps the form open', (tester) async {
    await tester.pumpWidget(_host(ReviewReportSheet(
      bookingId: 'b1',
      submit: (reason, note) async => throw const ApiException(409, 'already_reported'),
    )));
    final t = tester.element(find.byType(ReviewReportSheet)).t;
    await tester.tap(find.text(reviewReportLabel(t, 'spam')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(t.reportAlready), findsOneWidget);
    expect(find.byType(ReviewReportSheet), findsOneWidget);
  });

  test('reasons match the server list (backend REPORT_REASONS)', () {
    expect(reviewReportReasons, ['spam', 'offensive', 'personal_info', 'other']);
  });
}
