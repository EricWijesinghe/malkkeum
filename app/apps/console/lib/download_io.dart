import 'dart:io';

/// Desktop: writes into the user's Downloads folder. False when no such folder exists.
Future<bool> saveCsv(List<int> bytes, String filename) async {
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null) return false;
  final dir = Directory('$home${Platform.pathSeparator}Downloads');
  if (!dir.existsSync()) return false;
  await File('${dir.path}${Platform.pathSeparator}$filename').writeAsBytes(bytes, flush: true);
  return true;
}
