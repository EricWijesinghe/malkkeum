import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helpers for the store screenshot suites (tag `store_screenshots`, excluded from normal runs).
/// Renders real screens at exact store pixel sizes with the bundled Pretendard font.

/// One store capture size. Logical size = pixels / dpr, so every layout is a real device layout.
class ShotDevice {
  const ShotDevice(this.slug, this.width, this.height, this.dpr);
  final String slug;
  final int width;
  final int height;
  final double dpr;
}

/// App Store 6.9" / 6.5", iPad 13" and Google Play phone sizes (pixels).
const shotDevices = [
  ShotDevice('ios-6.9', 1320, 2868, 3),
  ShotDevice('ios-6.5', 1284, 2778, 3),
  ShotDevice('ipad-13', 2064, 2752, 2),
  ShotDevice('android', 1080, 2400, 3),
];

/// Comma lists from `--dart-define`, e.g. `--dart-define=SHOT_LANGS=ko,en`.
final shotLangs = const String.fromEnvironment('SHOT_LANGS', defaultValue: 'ko,en,ja,zh,vi').split(',');
final shotDeviceSlugs = const String.fromEnvironment('SHOT_DEVICES', defaultValue: 'ios-6.9,ios-6.5,ipad-13,android').split(',');

/// Where PNGs go (relative to the app package). The framing step reads from here.
final shotOutRoot = const String.fromEnvironment('SHOT_OUT', defaultValue: 'build/store_shots/raw');

/// Loads Pretendard (the app font) plus CJK fallbacks, and the Material icon font.
/// Flutter's test engine otherwise draws Ahem boxes for every glyph.
/// CJK fallbacks come from the Windows font folder (Yu Gothic, Microsoft YaHei), registered under the
/// family names the theme already falls back to ('Noto Sans JP' / 'Noto Sans SC').
Future<void> loadShotFonts() async {
  final uiLib = await Isolate.resolvePackageUri(Uri.parse('package:ui/ui.dart'));
  final fontDir = Directory('${File.fromUri(uiLib!).parent.parent.path}/assets/fonts');
  final pretendard = FontLoader('Pretendard');
  for (final f in fontDir.listSync().whereType<File>().where((f) => f.path.endsWith('.otf'))) {
    pretendard.addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
  }
  await pretendard.load();

  final winFonts = Platform.environment['SHOT_WIN_FONTS'] ?? r'C:\Windows\Fonts';
  Future<void> cjk(String family, String file) async {
    final f = File('$winFonts${Platform.pathSeparator}$file');
    if (!f.existsSync()) return;
    final loader = FontLoader(family)..addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }

  await cjk('Noto Sans SC', 'msyh.ttc');
  await cjk('Noto Sans JP', 'YuGothM.ttc');

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

/// Pumps frames for [duration] of fake time (no pumpAndSettle: looping animations never settle).
Future<void> shotSettle(WidgetTester tester, {Duration duration = const Duration(seconds: 2)}) async {
  for (var i = 0; i < duration.inMilliseconds ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Renders [app] at [device] size and writes it to [path] as a PNG.
Future<void> captureShot(WidgetTester tester, Widget app, ShotDevice device, String path) async {
  final boundary = GlobalKey();
  tester.view.devicePixelRatio = device.dpr;
  tester.view.physicalSize = Size(device.width.toDouble(), device.height.toDouble());
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(RepaintBoundary(key: boundary, child: app));
  await shotSettle(tester);
  await tester.runAsync(() async {
    final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: device.dpr);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes.buffer.asUint8List());
  });
}
