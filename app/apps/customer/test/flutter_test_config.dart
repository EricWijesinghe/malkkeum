import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:ui/ui.dart';

/// Runs once before every test file in this folder: loads intl date symbols so
/// `DateFormat(..., 'ko')` works outside a fully booted app, and stops idle
/// icon loops so `pumpAndSettle` can settle (icon3d tests turn them back on).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  Icon3D.idleMotion = false;
  await testMain();
}
