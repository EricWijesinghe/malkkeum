import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

/// No files: every Icon3D / logo frame falls back to its painter.
class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw FlutterError('missing $key');
}

final _empty = _EmptyBundle();
final _theme = buildTheme(BrandConfig.placeholder, Brightness.light);

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  theme: _theme,
  builder: (ctx, c) => DefaultAssetBundle(
    bundle: _empty,
    child: MediaQuery(
      data: MediaQuery.of(ctx).copyWith(disableAnimations: reduce),
      child: c!,
    ),
  ),
  home: Scaffold(body: Center(child: child)),
);

Finder _icon(String id) =>
    find.byWidgetPredicate((w) => w is Icon3D && w.id == id);

/// Scale of the spring transform (the innermost Transform under the icon).
double _scale(WidgetTester tester, String id) {
  final t = find.descendant(of: _icon(id), matching: find.byType(Transform));
  if (t.evaluate().isEmpty) return 1;
  return tester.widget<Transform>(t.last).transform.getMaxScaleOnAxis();
}

void main() {
  group('Icon3D idle', () {
    setUp(() => Icon3D.idleMotion = true);
    tearDown(() => Icon3D.idleMotion = false);

    testWidgets('float runs a ticker and lifts the art', (tester) async {
      await tester.pumpWidget(
        _app(const Icon3D('nav_home', idle: Icon3DIdle.float)),
      );
      var lift = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final t = tester.widget<Transform>(
          find
              .descendant(
                of: _icon('nav_home'),
                matching: find.byType(Transform),
              )
              .first,
        );
        lift = lift < -t.transform.getTranslation().y
            ? -t.transform.getTranslation().y
            : lift;
      }
      expect(tester.hasRunningAnimations, isTrue);
      expect(lift, greaterThan(0));
      expect(lift, lessThanOrEqualTo(48 * Motion.idleLift + 1e-6));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'reduced motion, disabled, muted TickerMode and the switch start no ticker',
      (tester) async {
        Future<void> expectStill(Widget w) async {
          await tester.pumpWidget(w);
          await tester.pump(const Duration(milliseconds: 100));
          expect(SchedulerBinding.instance.transientCallbackCount, 0);
          expect(tester.hasRunningAnimations, isFalse);
          await tester.pumpWidget(const SizedBox());
        }

        await expectStill(
          _app(const Icon3D('nav_home', idle: Icon3DIdle.sway), reduce: true),
        );
        await expectStill(
          _app(const Icon3D('nav_home', idle: Icon3DIdle.sway, enabled: false)),
        );
        await expectStill(
          _app(
            const TickerMode(
              enabled: false,
              child: Icon3D('nav_home', idle: Icon3DIdle.float),
            ),
          ),
        );
        Icon3D.idleMotion = false;
        await expectStill(
          _app(const Icon3D('nav_home', idle: Icon3DIdle.float)),
        );
      },
    );
  });

  testWidgets('attention kicks once (<= 1.12) and returns to 1', (
    tester,
  ) async {
    Widget icon(int n) => _app(Icon3D('ui_coupon', attention: n));
    await tester.pumpWidget(icon(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(icon(1));
    var peak = 1.0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final s = _scale(tester, 'ui_coupon');
      if (s > peak) peak = s;
    }
    expect(peak, greaterThan(1.04));
    expect(peak, lessThanOrEqualTo(Motion.activeScale));
    await tester.pumpAndSettle();
    expect(_scale(tester, 'ui_coupon'), closeTo(1, 1e-3));

    // Reduced motion: no kick at all.
    await tester.pumpWidget(
      _app(const Icon3D('ui_coupon', attention: 1), reduce: true),
    );
    await tester.pumpWidget(
      _app(const Icon3D('ui_coupon', attention: 2), reduce: true),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('highlight holds the press scale', (tester) async {
    await tester.pumpWidget(_app(const Icon3D('ui_bell')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(const Icon3D('ui_bell', highlight: true)));
    await tester.pumpAndSettle();
    expect(_scale(tester, 'ui_bell'), closeTo(Motion.pressScale, 1e-3));
    await tester.pumpWidget(_app(const Icon3D('ui_bell')));
    await tester.pumpAndSettle();
    expect(_scale(tester, 'ui_bell'), closeTo(1, 1e-3));
  });

  testWidgets(
    'AmountSwitcher slides the new value in; reduced motion swaps at once',
    (tester) async {
      String fmt(int v) => '$v원';
      await tester.pumpWidget(_app(AmountSwitcher(value: 1000, format: fmt)));
      await tester.pumpWidget(_app(AmountSwitcher(value: 2000, format: fmt)));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('1000원'), findsOneWidget);
      expect(find.text('2000원'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('1000원'), findsNothing);
      expect(find.text('2000원'), findsOneWidget);

      await tester.pumpWidget(
        _app(AmountSwitcher(value: 3000, format: fmt), reduce: true),
      );
      await tester.pump();
      expect(find.text('2000원'), findsNothing);
      expect(find.text('3000원'), findsOneWidget);
    },
  );

  testWidgets('ProgressLine grows to the fraction with a paint-only scale', (
    tester,
  ) async {
    double scaleX() => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(ProgressLine),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .entry(0, 0);
    await tester.pumpWidget(
      _app(const SizedBox(width: 200, child: ProgressLine(fraction: 0.5))),
    );
    expect(scaleX(), 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(scaleX(), inExclusiveRange(0, 0.5));
    await tester.pumpAndSettle();
    expect(scaleX(), closeTo(0.5, 1e-6));

    await tester.pumpWidget(
      _app(
        const SizedBox(width: 200, child: ProgressLine(fraction: 1)),
        reduce: true,
      ),
    );
    await tester.pump();
    expect(scaleX(), 1);
  });

  testWidgets('FadeThroughSwitcher: old out first, new in, then only new', (
    tester,
  ) async {
    Widget page(String s) =>
        _app(FadeThroughSwitcher(child: Text(s, key: ValueKey(s))));
    await tester.pumpWidget(page('a'));
    await tester.pumpWidget(page('b'));
    await tester.pump(Motion.fadeOut ~/ 2);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(find.text('b'), findsOneWidget);

    await tester.pumpWidget(
      _app(const FadeThroughSwitcher(child: Text('c', key: ValueKey('c')))),
    );
    await tester.pumpWidget(
      _app(
        const FadeThroughSwitcher(child: Text('d', key: ValueKey('d'))),
        reduce: true,
      ),
    );
    await tester.pump();
    expect(find.text('c'), findsNothing);
  });

  testWidgets('SegmentedControl thumb slides to the selected segment', (
    tester,
  ) async {
    var sel = 0;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (_, set) => SizedBox(
            width: 300,
            child: SegmentedControl<int>(
              segments: const [(0, 'A'), (1, 'B'), (2, 'C')],
              selected: sel,
              onChanged: (v) => set(() => sel = v),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
      Offset.zero,
    );
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(
      tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
      const Offset(2, 0),
    );
    await tester.pumpAndSettle();
    final thumb = tester.getRect(
      find.descendant(
        of: find.byType(AnimatedSlide),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(thumb.center.dx, closeTo(tester.getCenter(find.text('C')).dx, 1));
  });

  group('DahaeLogo', () {
    Color wordColor(WidgetTester tester) => tester
        .widget<Text>(find.text(BrandConfig.placeholder.name))
        .style!
        .color!;

    testWidgets(
      'wordmark is dark teal on light, white on dark; tagline shows',
      (tester) async {
        await tester.pumpWidget(
          _app(const DahaeLogo(wordmark: true, tagline: '집안일, 다 해드려요')),
        );
        expect(wordColor(tester), BrandConfig.placeholder.primary);
        expect(find.text('집안일, 다 해드려요'), findsOneWidget);
        await tester.pumpWidget(
          _app(const DahaeLogo(wordmark: true, onDark: true)),
        );
        expect(wordColor(tester), Colors.white);
      },
    );

    testWidgets(
      'animate plays once (frame fallback) and settles; reduced motion is instant',
      (tester) async {
        for (final v in [DahaeLogoVariant.threeD, DahaeLogoVariant.flat]) {
          await tester.pumpWidget(
            _app(DahaeLogo(key: ValueKey(v), variant: v, animate: true)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.hasRunningAnimations, isTrue);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(
          _app(
            const DahaeLogo(key: ValueKey('r'), animate: true),
            reduce: true,
          ),
        );
        expect(tester.hasRunningAnimations, isFalse);
        final painter = tester
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byType(DahaeLogo),
                matching: find.byType(CustomPaint),
              ),
            )
            .map((p) => p.painter)
            .whereType<DahaeMarkPainter>()
            .single;
        expect(painter.checkT, 1);
      },
    );
  });

  testWidgets('SuccessMark fires one haptic and settles', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add('${call.arguments}');
        }
        return null;
      },
    );
    await tester.pumpWidget(_app(const SuccessMark()));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(calls, ['HapticFeedbackType.mediumImpact']);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets('PrimaryButton picks an AA label for a light fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PrimaryButton(
          label: 'Go',
          color: BrandConfig.placeholder.sun,
          onPressed: () {},
        ),
      ),
    );
    final style = DefaultTextStyle.of(tester.element(find.text('Go'))).style;
    expect(style.color, Neutral.c900);
  });
}
