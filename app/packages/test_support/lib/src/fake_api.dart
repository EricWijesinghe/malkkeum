import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// One request the app made, already decoded. `path` has the `/v1` prefix removed.
class ApiCall {
  const ApiCall({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
    required this.headers,
  });

  final String method;
  final String path;
  final Map<String, String> query;

  /// Decoded JSON body, or null when the request had none.
  final Object? body;
  final Map<String, String> headers;

  Map<String, dynamic> get json => Map<String, dynamic>.from(body! as Map);
}

/// Return this from a route handler to choose the HTTP status (default 200).
class ApiReply {
  const ApiReply(this.status, [this.body]);
  final int status;
  final Object? body;
}

/// A route handler gets the call and returns a JSON-able body (200), or an [ApiReply].
typedef RouteHandler = FutureOr<Object?> Function(ApiCall call);

class _Route {
  _Route(this.method, this.pattern, this.handler);
  final String method;
  final RegExp pattern;
  final RouteHandler handler;
}

/// Route-table fake for the backend. Patterns are regexes matched against the full
/// path after `/v1` (anchors are added for you). Unmatched calls answer 404 `not_found`
/// and are still recorded in [calls], so a test can see what the app asked for.
class FakeApi {
  final List<_Route> _routes = [];

  /// Every request, in order.
  final List<ApiCall> calls = [];

  late final http.Client client = MockClient(_handle);

  void on(String method, String pattern, RouteHandler handler) {
    _routes.add(_Route(method, RegExp('^$pattern\$'), handler));
  }

  void onGet(String pattern, RouteHandler handler) => on('GET', pattern, handler);
  void onPost(String pattern, RouteHandler handler) => on('POST', pattern, handler);
  void onPut(String pattern, RouteHandler handler) => on('PUT', pattern, handler);
  void onPatch(String pattern, RouteHandler handler) => on('PATCH', pattern, handler);
  void onDelete(String pattern, RouteHandler handler) => on('DELETE', pattern, handler);

  /// Constant reply for a route.
  void reply(String method, String pattern, Object? body, {int status = 200}) {
    on(method, pattern, (_) => ApiReply(status, body));
  }

  /// Calls made to [method] [path] (path without `/v1`, e.g. `/bookings`).
  List<ApiCall> callsTo(String method, String path) => [
        for (final c in calls)
          if (c.method == method && c.path == path) c,
      ];

  ApiCall? lastCall(String method, String path) => callsTo(method, path).lastOrNull;

  Future<http.Response> _handle(http.Request req) async {
    final raw = req.url.path;
    final path = raw.startsWith('/v1') ? raw.substring(3) : raw;
    final body = _jsonOrNull(req.body);
    final call = ApiCall(
      method: req.method,
      path: path,
      query: req.url.queryParameters,
      body: body,
      headers: req.headers,
    );
    calls.add(call);
    for (final r in _routes) {
      if (r.method != req.method || !r.pattern.hasMatch(path)) continue;
      final out = await r.handler(call);
      if (out is ApiReply) return _respond(out.status, out.body);
      return _respond(200, out);
    }
    return _respond(404, {
      'error': {'code': 'not_found', 'path': path},
    });
  }

  /// Multipart uploads are not JSON: they reach the route with a null body.
  static Object? _jsonOrNull(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static http.Response _respond(int status, Object? body) => http.Response(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
}
