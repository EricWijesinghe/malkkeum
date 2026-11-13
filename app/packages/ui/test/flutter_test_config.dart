import 'dart:async';

import 'package:ui/ui.dart';

/// Runs once before every test file in this folder: stops idle icon loops so
/// `pumpAndSettle` can settle. The Icon3D idle tests turn them back on.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Icon3D.idleMotion = false;
  await testMain();
}
