// Web splash hand-off: the page shell hides its logo once the home has data. Native builds do nothing.
export 'web_ready_stub.dart' if (dart.library.js_interop) 'web_ready_web.dart';
