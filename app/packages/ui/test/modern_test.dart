import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: buildTheme(BrandConfig.placeholder, Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('SegmentedControl selects tapped segment; tap target >= 48dp', (
    tester,
  ) async {
    var picked = 0;
    await tester.pumpWidget(
      _host(
        SegmentedControl<int>(
          segments: const [(0, '일반'), (1, '이사')],
          selected: 0,
          onChanged: (v) => picked = v,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final segment = find.bySemanticsLabel('이사');
    expect(tester.getSize(segment).height, greaterThanOrEqualTo(48));
    await tester.tap(segment);
    expect(picked, 1);
  });

  testWidgets('RatingStars exposes its value to semantics', (tester) async {
    await tester.pumpWidget(_host(const RatingStars(rating: 4.5)));
    expect(find.bySemanticsLabel('4.5 / 5'), findsOneWidget);
  });

  testWidgets('CountUp jumps to the new value under reduced motion', (
    tester,
  ) async {
    Widget counter(int v) =>
        _host(CountUp(value: v, format: (x) => '$x'), reduceMotion: true);
    await tester.pumpWidget(counter(1000));
    await tester.pumpWidget(counter(2000));
    expect(find.text('2000'), findsOneWidget);
  });

  testWidgets('CountUp tweens through intermediate values normally', (
    tester,
  ) async {
    Widget counter(int v) => _host(CountUp(value: v, format: (x) => '$x'));
    await tester.pumpWidget(counter(0));
    await tester.pumpWidget(counter(100));
    await tester.pump(const Duration(milliseconds: 100));
    final shown = int.parse(tester.widget<Text>(find.byType(Text)).data!);
    expect(shown, inInclusiveRange(1, 99));
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('EnterMotion shows child immediately under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const EnterMotion(child: Text('hi')), reduceMotion: true),
    );
    expect(find.text('hi'), findsOneWidget);
    // No pending animation timers left behind.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('PriceTag formats won amount', (tester) async {
    await tester.pumpWidget(
      _host(const PriceTag(amount: 120000, locale: 'ko')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('120'), findsOneWidget);
  });
}
