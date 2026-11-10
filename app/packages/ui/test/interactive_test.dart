import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: buildTheme(BrandConfig.placeholder, Brightness.dark),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

Future<void> _frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('Pressable fires onTap on a clean tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(Pressable(
      onTap: () => taps++,
      child: const SizedBox(width: 120, height: 120),
    )));
    await tester.tap(find.byType(SizedBox).first);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('Pressable ignores a drag past touch slop (scrolling is not a tap)', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(Pressable(
      onTap: () => taps++,
      child: const SizedBox(width: 120, height: 120),
    )));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox).first));
    await gesture.moveBy(const Offset(0, 60));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
  });

  testWidgets('Pressable springs down while held and back on release', (tester) async {
    await tester.pumpWidget(_host(Pressable(
      onTap: () {},
      child: const SizedBox(width: 120, height: 120),
    )));
    final scale = find.descendant(of: find.byType(Pressable), matching: find.byType(Transform)).first;
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox).first));
    await _frames(tester, 12);
    expect(tester.widget<Transform>(scale).transform.entry(0, 0), lessThan(1.0));
    await gesture.up();
    await _frames(tester, 40);
    expect(tester.widget<Transform>(scale).transform.entry(0, 0), closeTo(1.0, 0.01));
  });

  testWidgets('Tilt3D rotates toward the hovered pointer with perspective', (tester) async {
    await tester.pumpWidget(_host(const Tilt3D(child: SizedBox(width: 200, height: 200))));
    final tilt = find.byType(Tilt3D);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(tilt) + const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 300));
    final m = tester.widget<Transform>(find.descendant(of: tilt, matching: find.byType(Transform)).first).transform;
    expect(m.entry(3, 2), closeTo(0.001, 1e-4));
    expect(m.storage[0], lessThan(1.0), reason: 'rotateY should shorten the x basis');
  });

  testWidgets('Tilt3D stays flat under reduced motion', (tester) async {
    await tester.pumpWidget(_host(const Tilt3D(child: SizedBox(width: 200, height: 200)), reduceMotion: true));
    final tilt = find.byType(Tilt3D);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(tilt) + const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 300));
    final m = tester.widget<Transform>(find.descendant(of: tilt, matching: find.byType(Transform)).first).transform;
    expect(m.storage[0], closeTo(1.0, 1e-9));
  });

  testWidgets('ServiceGlyph renders at 36 and 120 in both themes', (tester) async {
    for (final b in Brightness.values) {
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(BrandConfig.placeholder, b),
        home: const Scaffold(
          body: Row(children: [ServiceGlyph('kitchen', size: 36), ServiceGlyph('move_in', size: 120)]),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(ServiceGlyph), findsNWidgets(2));
    }
  });
}
