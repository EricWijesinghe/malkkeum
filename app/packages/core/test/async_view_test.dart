import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

final T _t = lookupT(const Locale('en'));

Widget _host(Future<List<String>> Function() load) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: T.localizationsDelegates,
  supportedLocales: T.supportedLocales,
  theme: buildTheme(BrandConfig.placeholder, Brightness.light),
  home: Scaffold(
    body: AsyncView<List<String>>(
      load: load,
      builder: (context, rows, reload) => Column(
        children: [
          for (final r in rows) Text(r),
          TextButton(onPressed: reload, child: const Text('refresh')),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('a failed refresh keeps the data on screen and says why', (tester) async {
    var online = true;
    await tester.pumpWidget(
      _host(() async {
        if (!online) throw const ApiException(0, 'network');
        return ['row-1', 'row-2'];
      }),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('row-1'), findsOneWidget);

    online = false;
    await tester.tap(find.text('refresh'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('row-1'), findsOneWidget, reason: 'the list stays');
    expect(find.text('row-2'), findsOneWidget);
    expect(find.byType(ErrorRetry), findsNothing);
    expect(find.text(_t.errorNetwork), findsOneWidget, reason: 'a toast, not a full-screen error');

    online = true;
    await tester.tap(find.text('refresh'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('row-1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // let the toast leave
  });

  testWidgets('a failed first load shows the error state, never the raw exception; retry loads', (tester) async {
    var online = false;
    await tester.pumpWidget(
      _host(() async {
        if (!online) throw const SocketException('Connection refused (OS Error: 111)');
        return ['row-1'];
      }),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ErrorRetry), findsOneWidget);
    expect(find.text(_t.errorGeneric), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.textContaining('OS Error'), findsNothing);

    online = true;
    await tester.tap(find.text(_t.retry));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('row-1'), findsOneWidget);
    expect(find.byType(ErrorRetry), findsNothing);
  });
}
