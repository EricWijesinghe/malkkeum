// Saves a CSV the owner downloaded. Web triggers a browser download; desktop writes to Downloads.
export 'download_stub.dart' if (dart.library.io) 'download_io.dart' if (dart.library.js_interop) 'download_web.dart';
