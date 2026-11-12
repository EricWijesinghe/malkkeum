import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

/// Goldens (tag `golden`) are generated and compared only on the CI runner, where
/// fonts and rasterisation are pinned. Locally they skip; `--update-goldens` on the
/// runner writes the baselines.
bool goldensEnabled(String baseline) =>
    Platform.environment['CI'] == 'true' &&
    (autoUpdateGoldenFiles || File(baseline).existsSync());

/// Real fonts (Pretendard + CJK fallbacks + Material icons) instead of Ahem boxes.
Future<void> loadGoldenFonts(WidgetTester tester) async {
  await tester.runAsync(loadShotFonts);
}

/// Decodes the art of every [Icon3D] on screen (real async I/O), so the next
/// frames paint the 3D icons instead of their blank loading frame.
Future<void> precacheIcon3D(WidgetTester tester) async {
  final icons = tester.widgetList<Icon3D>(find.byType(Icon3D)).toList();
  final context = tester.element(find.byType(Icon3D).first);
  await tester.runAsync(() async {
    for (final i in icons) {
      await precacheImage(
        AssetImage(
          Icon3DRegistry.assetFor(i.id, idle: !i.active, size: i.size),
          package: Icon3DRegistry.package,
        ),
        context,
        onError: (_, _) {},
      );
    }
  });
  await tester.pump();
}
