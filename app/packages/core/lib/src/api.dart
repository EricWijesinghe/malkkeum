import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session.dart';

/// API base URL. Override at build time: --dart-define=API_BASE=https://api.example.com
String defaultApiBase() {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  // Android emulator reaches the host machine through 10.0.2.2.
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8080';
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
  ApiClient({required this.baseUrl, required this.session, http.Client? client}) : _http = client ?? http.Client() {
    session.attach(this);
  }

  final String baseUrl;
  final Session session;
  final http.Client _http;
  static const _timeout = Duration(seconds: 20);
  Future<bool>? _refreshing;

  Uri _uri(String path, [Map<String, String?>? query]) {
    final q = {for (final e in (query ?? {}).entries) if (e.value != null) e.key: e.value!};
    return Uri.parse('$baseUrl/v1$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> get(String path, {Map<String, String?>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body: body);
  Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String?>? query, bool retried = false}) async {
    final req = http.Request(method, _uri(path, query))..headers['Content-Type'] = 'application/json';
    final token = session.accessToken;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) req.body = jsonEncode(body);
    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(_timeout));
    } on TimeoutException {
      throw const ApiException(0, 'timeout');
    } catch (_) {
      throw const ApiException(0, 'network');
    }
    if (res.statusCode == 401 && !retried && session.refreshToken != null && !path.startsWith('/auth/')) {
      if (await _refresh()) return _send(method, path, body: body, query: query, retried: true);
    }
    final decoded = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    final code = decoded is Map ? ((decoded['error'] as Map?)?['code'] as String?) : null;
    if (res.statusCode == 401) await session.clear();
    throw ApiException(res.statusCode, code ?? 'http_${res.statusCode}');
  }

  /// Single-flight refresh so parallel 401s rotate the token once.
  Future<bool> _refresh() => _refreshing ??= () async {
        try {
          final r = await _send('POST', '/auth/refresh', body: {'refresh_token': session.refreshToken}, retried: true) as Map<String, dynamic>;
          await session.save(r);
          return true;
        } catch (_) {
          await session.clear();
          return false;
        } finally {
          _refreshing = null;
        }
      }();

  /// Multipart image upload; returns the stored file URL.
  Future<String> upload(List<int> bytes, String filename) async {
    final req = http.MultipartRequest('POST', _uri('/uploads'))
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final res = await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 60)));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) throw ApiException(res.statusCode, ((decoded as Map)['error'] as Map?)?['code'] as String? ?? 'upload_failed');
    return (decoded as Map)['url'] as String;
  }

  Uri wsUri() {
    final base = Uri.parse(baseUrl);
    return base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: '/v1/ws', queryParameters: {'token': session.accessToken ?? ''});
  }
}
