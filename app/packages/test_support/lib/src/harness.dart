import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'env.dart';

/// Realtime that never opens a WebSocket (a real socket would leave reconnect timers
/// pending at the end of a widget test). Live-event behaviour is covered at the
/// core level, not here.
class FakeRealtime extends Realtime {
  FakeRealtime(super.api);

  @override
  void connect() {}
}

/// Pumps frames for [duration] without `pumpAndSettle`, which never returns while
/// looping animations (aurora, live dot, parallax) are running.
Future<void> settle(WidgetTester tester, {Duration duration = const Duration(seconds: 2)}) async {
  final steps = duration.inMilliseconds ~/ 100;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps until [finder] matches or [timeout] of fake time passes. Fails with a clear message otherwise.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final steps = timeout.inMilliseconds ~/ 100;
  for (var i = 0; i < steps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets, reason: 'timed out waiting for $finder');
}

/// Sets the logical viewport (DPR 1) and restores it after the test.
void setViewport(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = logical;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Common phone size (iPhone 14 class, logical pixels).
const phoneSize = Size(390, 844);

/// Phone width, tall enough that no content scrolls under the frosted bottom bar
/// (the contrast checker would sample the blur instead of the real background).
const tallPhoneSize = Size(390, 1600);

/// Tablet / desktop width that triggers the side rail and split views.
const wideSize = Size(1280, 900);

/// Replaces the tree, then advances time so delayed timers (stagger-in, reconnects) fire before the test ends.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Convenience: a fresh environment with the default (signed-in, Korean, dark) setup.
Future<TestEnv> freshEnv({bool signedIn = true, String localeCode = 'ko', ThemeMode mode = ThemeMode.dark}) =>
    TestEnv.create(signedIn: signedIn, localeCode: localeCode, themeMode: mode);

/// Korean strings for lookups in tests. Prefer this over hard-coded literals.
final T koT = lookupT(const Locale('ko'));
