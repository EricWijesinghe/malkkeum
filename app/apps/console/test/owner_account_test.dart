import 'package:console/widgets/owner_forms.dart';
import 'package:console/widgets/owner_totp_dialog.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
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

/// Opens [open] from a button and stores whatever the dialog resolves to in [result].
Future<void> _openFrom(WidgetTester tester, Future<Object?> Function(BuildContext) open, List<Object?> result) async {
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result.add(await open(context)),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('owner requests carry the code in the X-Owner-Totp header only', () {
    expect(ownerHeaders('123456'), {'X-Owner-Totp': '123456'});
  });

  testWidgets('owner code must be six digits before it is sent', (tester) async {
    final result = <Object?>[];
    await _openFrom(tester, (c) => askOwnerTotp(c), result);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'five digits do not submit');
    expect(result, isEmpty);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(result, ['123456']);
  });

  testWidgets('cancelling an owner prompt sends nothing', (tester) async {
    final result = <Object?>[];
    await _openFrom(tester, (c) => askOwnerTotp(c), result);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, [null]);
  });

  testWidgets('a form with two fields stays disabled until both are filled and trims values', (tester) async {
    final result = <Object?>[];
    await _openFrom(
      tester,
      (c) => askFields(
        c,
        title: 'T',
        body: 'B',
        confirm: 'OK',
        fields: const [FieldSpec('a'), FieldSpec('b', obscure: true)],
      ),
      result,
    );

    FilledButton confirm() => tester.widget<FilledButton>(find.byType(FilledButton));
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), '  one  ');
    await tester.pump();
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(1), 'two');
    await tester.pump();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(result, [
      ['one', 'two'],
    ]);
  });
}
