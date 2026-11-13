import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: buildTheme(BrandConfig.placeholder, Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('retry shows progress and ignores taps until the retry settles', (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      _app(
        ErrorRetry(
          message: 'No connection',
          retryLabel: 'Retry',
          onRetry: () {
            calls++;
            return pending.future;
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Retry'), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1, reason: 'a second tap while retrying is ignored');

    pending.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(calls, 2);
  });

  testWidgets('the message is announced as a live region and the retry is a 48dp button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(ErrorRetry(message: 'No connection', retryLabel: 'Retry', onRetry: () {})));
    await tester.pump(const Duration(seconds: 1));

    final live = find.ancestor(
      of: find.text('No connection'),
      matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true),
    );
    expect(live, findsOneWidget);
    expect(tester.getSemantics(find.text('Retry')), isSemantics(label: 'Retry', isButton: true, hasTapAction: true, isEnabled: true));
    expect(tester.getSize(find.bySubtype<OutlinedButton>()).height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('the compact card sits inline: message, retry and no full-page art', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            ErrorRetry(compact: true, message: 'No connection', retryLabel: 'Retry', onRetry: () => calls++),
            const Text('below'),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byType(ServiceGlyph), findsNothing);
    expect(tester.getSize(find.byType(ErrorRetry)).height, lessThan(120));
    expect(tester.getSize(find.bySubtype<TextButton>()).height, greaterThanOrEqualTo(48));
    await tester.tap(find.text('Retry'));
    expect(calls, 1);
  });

  testWidgets('a secondary action sits under retry', (tester) async {
    await tester.pumpWidget(
      _app(
        ErrorRetry(
          message: 'No connection',
          retryLabel: 'Retry',
          onRetry: () {},
          secondary: TextButton(onPressed: () {}, child: const Text('Sign out')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(find.text('Sign out')).dy, greaterThan(tester.getTopLeft(find.text('Retry')).dy));
  });

  testWidgets('reduced motion shows the state at once, with no entrance', (tester) async {
    await tester.pumpWidget(_app(ErrorRetry(message: 'No connection', retryLabel: 'Retry', onRetry: () {}), reduceMotion: true));
    await tester.pump();
    final fade = tester.widget<Opacity>(find.ancestor(of: find.text('No connection'), matching: find.byType(Opacity)).first);
    expect(fade.opacity, 1);
  });
}
