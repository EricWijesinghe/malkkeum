import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Runs once before every test file in this folder: loads intl date symbols so
/// `DateFormat(..., 'ko')` works outside a fully booted app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
