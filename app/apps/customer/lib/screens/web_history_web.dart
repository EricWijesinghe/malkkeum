import 'dart:js_interop';

@JS('history.replaceState')
external void _replaceState(JSAny? data, JSString title, JSString url);

/// Rewrites the address bar without reloading (drops the consumed deep-link hash).
void replaceBrowserUrl(String url) => _replaceState(null, ''.toJS, url.toJS);
