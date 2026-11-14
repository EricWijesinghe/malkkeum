import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session.dart';

/// API base URL. Override at build time: --dart-define=API_BASE=https://api.example.com
const _localHosts = {'localhost', '127.0.0.1', ''};

/// The parameters exist for tests; apps call `defaultApiBase()`.
String defaultApiBase({
  String fromEnv = const String.fromEnvironment('API_BASE'),
  bool release = kReleaseMode,
  bool web = kIsWeb,
}) {
  if (fromEnv.isNotEmpty) return fromEnv;
  // Deployed web build (console): the API lives on the same domain, so one build fits every install.
  if (web && !_localHosts.contains(Uri.base.host)) return Uri.base.origin;
  // A store build without API_BASE would send logins in cleartext to the device itself: stop at launch.
  if (release && !web) {
    throw StateError(
      'API_BASE is not set. Build with --dart-define=API_BASE=https://<domain>',
    );
  }
  // Android emulator reaches the host machine through 10.0.2.2.
  if (!web && Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://127.0.0.1:8080';
}

/// A failed call. `code` is the server's stable error code (see backend error.rs).
class ApiException implements Exception {
  const ApiException(this.status, this.code);
  final int status;
  final String code;
  bool get isNetwork => status == 0;

  @override
  String toString() => 'ApiException($status, $code)';
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.session, http.Client? client})
    : _http = client ?? http.Client() {
    session.attach(this);
  }

  final String baseUrl;
  final Session session;
  final http.Client _http;
  static const _timeout = Duration(seconds: 20);
  Future<bool>? _refreshing;

  Uri _uri(String path, [Map<String, String?>? query]) {
    final q = {
      for (final e in (query ?? {}).entries)
        if (e.value != null) e.key: e.value!,
    };
    return Uri.parse('$baseUrl/v1$path')
        .replace(queryParameters: q.isEmpty ? null : q);
  }

  /// Cold start: only the refresh token is restored, so get an access token once, before the first
  /// screens fire their calls. Calls made meanwhile wait for it instead of each failing with a 401.
  /// Never throws; offline, the first real call retries.
  Future<void> warmUp() async {
    if (session.accessToken != null || session.refreshToken == null) return;
    await _refresh();
  }

  Future<dynamic> get(String path, {Map<String, String?>? query}) =>
      _send('GET', path, query: query);

  /// One page of a cursor list. The server sends `X-Next-Cursor` while more rows follow.
  Future<({List<dynamic> items, String? next})> getPage(
    String path, {
    Map<String, String?>? query,
    String? cursor,
  }) async {
    String? next;
    final body = await _exec(
      path,
      () => http.Request('GET', _uri(path, {...?query, 'cursor': cursor})),
      onHeaders: (h) => next = h['x-next-cursor'],
    );
    return (items: (body as List?) ?? const <dynamic>[], next: next);
  }

  /// [idempotencyKey]: send the same key on every retry of one user action (server replays the first answer for 24h).
  /// [headers]: extra request headers, such as the owner's `X-Owner-Totp` on owner-only actions.
  Future<dynamic> post(
    String path, [
    Object? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  ]) => _send(
    'POST',
    path,
    body: body,
    idempotencyKey: idempotencyKey,
    headers: headers,
  );

  /// A fresh key for one user action: 128 bits from a secure RNG, hex.
  static String newIdempotencyKey() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// [headers]: extra request headers, e.g. the owner's authenticator code on a guarded change.
  Future<dynamic> put(
    String path, [
    Object? body,
    Map<String, String>? headers,
  ]) => _send('PUT', path, body: body, headers: headers);
  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);
  Future<dynamic> delete(
    String path, [
    Object? body,
    Map<String, String>? headers,
  ]) => _send('DELETE', path, body: body, headers: headers);

  /// Raw response bytes (CSV exports). The bearer token stays in the header, never in the URL.
  Future<List<int>> getBytes(String path, {Map<String, String?>? query}) async {
    final bytes = await _exec(
      path,
      () => http.Request('GET', _uri(path, query)),
      raw: true,
    );
    return bytes as List<int>;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String?>? query,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) => _exec(path, () {
    final req = http.Request(method, _uri(path, query))
      ..headers['Content-Type'] = 'application/json';
    if (headers != null) req.headers.addAll(headers);
    if (idempotencyKey != null) req.headers['Idempotency-Key'] = idempotencyKey;
    if (headers != null) req.headers.addAll(headers);
    if (body != null) req.body = jsonEncode(body);
    return req;
  });

  /// Sends a request (rebuilt on retry), refreshing the access token once on 401.
  Future<dynamic> _exec(
    String path,
    http.BaseRequest Function() build, {
    Duration timeout = _timeout,
    bool retried = false,
    bool raw = false,
    void Function(Map<String, String> headers)? onHeaders,
  }) async {
    final pending = _refreshing;
    if (pending != null && !retried && !path.startsWith('/auth/')) {
      await pending;
    }
    final req = build();
    final token = session.accessToken;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _http.send(req).timeout(timeout),
      );
    } on TimeoutException {
      throw const ApiException(0, 'timeout');
    } catch (_) {
      throw const ApiException(0, 'network');
    }
    if (res.statusCode == 401 &&
        !retried &&
        session.refreshToken != null &&
        !path.startsWith('/auth/')) {
      if (await _refresh()) {
        return _exec(
          path,
          build,
          timeout: timeout,
          retried: true,
          raw: raw,
          onHeaders: onHeaders,
        );
      }
    }
    final decoded = raw ? res.bodyBytes : _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      onHeaders?.call(res.headers);
      return decoded;
    }
    final code = decoded is Map
        ? ((decoded['error'] as Map?)?['code'] as String?)
        : null;
    throw ApiException(res.statusCode, code ?? 'http_${res.statusCode}');
  }

  /// Proxies can answer with HTML (502, 504): never let a decode error escape as a crash.
  static Object? _decode(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  /// Single-flight refresh so parallel 401s rotate the token once. Only a rejected refresh
  /// token signs the user out; a network blip keeps the session for the next attempt.
  Future<bool> _refresh() => _refreshing ??= () async {
    try {
      final r = await _exec('/auth/refresh', () {
        return http.Request('POST', _uri('/auth/refresh'))
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({'refresh_token': session.refreshToken});
      }, retried: true) as Map<String, dynamic>;
      await session.save(r);
      return true;
    } on ApiException catch (e) {
      if (e.status == 400 || e.status == 401 || e.status == 403) {
        await session.clear();
      }
      return false;
    } finally {
      _refreshing = null;
    }
  }();

  /// Multipart image upload; returns the stored file URL.
  Future<String> upload(List<int> bytes, String filename) async {
    final r = await _exec(
      '/uploads',
      () => http.MultipartRequest('POST', _uri('/uploads'))
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        ),
      timeout: const Duration(seconds: 60),
    );
    final url = r is Map ? r['url'] as String? : null;
    if (url == null) throw const ApiException(500, 'upload_failed');
    return url;
  }

  /// Socket address carrying a fresh single-use ticket (valid 30 s). The access token stays out of the URL.
  Future<Uri> wsUri() async {
    final r = await post('/realtime/ticket');
    final ticket = r is Map ? r['ticket'] as String? : null;
    if (ticket == null || ticket.isEmpty) {
      throw const ApiException(500, 'ticket_missing');
    }
    final base = Uri.parse(baseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/v1/ws',
      queryParameters: {'ticket': ticket},
    );
  }
}
