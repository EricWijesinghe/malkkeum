/// Platforms without a save path: the caller shows "download in the web console".
Future<bool> saveCsv(List<int> bytes, String filename) async => false;
