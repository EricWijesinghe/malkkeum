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
  testWidgets('submit stays disabled until a kind and a summary are given, then sends both', (tester) async {
    String? sentKind;
    String? sentSummary;
    await tester.pumpWidget(_host(CaseReportSheet(
      kinds: const ['damage', 'complaint'],
      submit: (kind, summary) async {
        sentKind = kind;
        sentSummary = summary;
      },
    )));
    final button = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.text('파손'));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull, reason: 'summary still empty');

    await tester.enterText(find.byType(TextField), '  벽에 흠집이 났어요  ');
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(sentKind, 'damage');
    expect(sentSummary, '벽에 흠집이 났어요');
  });

  testWidgets('emergency card shows 112 and 119, and skips a missing shop number', (tester) async {
    await tester.pumpWidget(_host(const EmergencyContactsCard(contacts: [
      {'label': 'police_fire_emergency', 'number': '112'},
      {'label': 'fire_rescue', 'number': '119'},
      {'label': 'shop', 'number': null},
    ])));
    expect(find.text('112'), findsOneWidget);
    expect(find.text('119'), findsOneWidget);
    expect(find.text('고객센터'), findsNothing);
  });
}
