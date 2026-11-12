import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Widget _app({required Widget home, bool reduce = false}) => MaterialApp(
  theme: buildTheme(BrandConfig.placeholder, Brightness.light),
  // Wrapping the Navigator too, so pushed routes see the reduced-motion flag.
  builder: (ctx, child) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: child!,
  ),
  home: Scaffold(body: Center(child: home)),
);

bool _isPerspective(Widget w) => w is Transform && w.transform.entry(3, 2) != 0;

Future<void> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await tester.pump();
  await mouse.moveTo(tester.getCenter(target) + const Offset(50, 10));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('ServiceCard3D tilts on hover', (tester) async {
    await tester.pumpWidget(
      _app(
        home: const SizedBox(
          width: 180,
          child: ServiceCard3D(code: 'studio', title: 'Studio'),
        ),
      ),
    );
    await _hover(tester, find.byType(ServiceCard3D));
    expect(find.byWidgetPredicate(_isPerspective), findsWidgets);
  });

  testWidgets('ServiceCard3D drops the tilt under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        reduce: true,
        home: const SizedBox(
          width: 180,
          child: ServiceCard3D(code: 'studio', title: 'Studio'),
        ),
      ),
    );
    await _hover(tester, find.byType(ServiceCard3D));
    expect(find.byWidgetPredicate(_isPerspective), findsNothing);
  });

  Future<void> pushDetail(WidgetTester tester, {required bool reduce}) async {
    await tester.pumpWidget(
      _app(
        reduce: reduce,
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(builder: (_) => const Text('detail')),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
  }

  testWidgets('Depth3D page transition turns the incoming route', (
    tester,
  ) async {
    await pushDetail(tester, reduce: false);
    expect(find.byWidgetPredicate(_isPerspective), findsWidgets);
  });

  testWidgets('Depth3D page transition is skipped under reduced motion', (
    tester,
  ) async {
    await pushDetail(tester, reduce: true);
    expect(find.byWidgetPredicate(_isPerspective), findsNothing);
  });

  testWidgets(
    'Depth3DPageTransitionsBuilder is the Android/Windows/Linux route builder',
    (tester) async {
      final theme = buildTheme(BrandConfig.placeholder, Brightness.light);
      final builders = theme.pageTransitionsTheme.builders;
      expect(
        builders[TargetPlatform.android],
        isA<Depth3DPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.windows],
        isA<Depth3DPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.linux],
        isA<Depth3DPageTransitionsBuilder>(),
      );
    },
  );

  testWidgets('EarningsSparkline sweeps in, then rests with the full series', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        home: const SizedBox(
          width: 240,
          child: EarningsSparkline(
            values: [10, 40, 25, 60],
            semanticLabel: 'earnings',
          ),
        ),
      ),
    );
    EarningsSparklinePainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) =>
                        w is CustomPaint &&
                        w.painter is EarningsSparklinePainter,
                  ),
                )
                .painter!
            as EarningsSparklinePainter;

    await tester.pump(const Duration(milliseconds: 100));
    expect(painter().progress, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(painter().progress, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'EarningsSparkline with fewer than two points draws nothing and does not throw',
    (tester) async {
      await tester.pumpWidget(
        _app(
          home: const SizedBox(
            width: 240,
            child: EarningsSparkline(values: [42]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('SuccessMark celebration plays and stops', (tester) async {
    await tester.pumpWidget(_app(home: const SuccessMark()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  double flipCos(WidgetTester tester) => tester
      .widget<Transform>(
        find
            .descendant(
              of: find.byType(FlipIn),
              matching: find.byType(Transform),
            )
            .first,
      )
      .transform
      .storage[0];

  testWidgets('FlipIn turns from edge-on to face-on, then rests', (
    tester,
  ) async {
    await tester.pumpWidget(_app(home: const FlipIn(child: Text('ok'))));
    await tester.pump();
    expect(flipCos(tester), closeTo(0, 0.05));
    await tester.pumpAndSettle();
    expect(flipCos(tester), closeTo(1, 1e-6));
  });

  testWidgets('FlipIn starts face-on under reduced motion', (tester) async {
    await tester.pumpWidget(
      _app(reduce: true, home: const FlipIn(child: Text('ok'))),
    );
    await tester.pump();
    expect(flipCos(tester), closeTo(1, 1e-6));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Skeleton shimmers while loading', (tester) async {
    await tester.pumpWidget(_app(home: const SkeletonList(count: 2)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.hasRunningAnimations, isTrue);
    expect(find.byType(Skeleton), findsNWidgets(2));
  });

  testWidgets('Skeleton is static under reduced motion', (tester) async {
    await tester.pumpWidget(
      _app(reduce: true, home: const SkeletonList(count: 2)),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
