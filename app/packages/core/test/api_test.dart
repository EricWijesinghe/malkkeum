import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory stand-in for the OS keystore.
class FakeStorage extends FlutterSecureStorage {
  FakeStorage();
  final data = <String, String>{};

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data[key];

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async =>
      value == null ? data.remove(key) : data[key] = value;

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data.remove(key);
}

http.Response json(int status, Object body) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const tokens = {'access_token': 'new-access', 'refresh_token': 'new-refresh', 'role': 'customer', 'subject': 'u1'};

Future<(ApiClient, Session, FakeStorage)> signedIn(MockClientHandler handler) async {
  final storage = FakeStorage();
  final session = Session(namespace: 't', storage: storage);
  final api = ApiClient(baseUrl: 'http://x', session: session, client: MockClient(handler));
  await session.save({'access_token': 'old-access', 'refresh_token': 'old-refresh', 'role': 'customer', 'subject': 'u1'});
  storage.data['app.locale'] = 'en';
  return (api, session, storage);
}

void main() {
  test('expired access token is refreshed once and the call retried', () async {
    var refreshes = 0;
    final (api, session, _) = await signedIn((req) async {
      if (req.url.path == '/v1/auth/refresh') {
        refreshes++;
        return json(200, tokens);
      }
      return req.headers['Authorization'] == 'Bearer new-access' ? json(200, {'ok': true}) : json(401, {'error': {'code': 'unauthorized'}});
    });
    final results = await Future.wait([api.get('/me'), api.get('/me/coupons')]);
    expect(results, everyElement(equals({'ok': true})));
    expect(refreshes, 1, reason: 'parallel 401s share one refresh');
    expect(session.refreshToken, 'new-refresh');
  });

  test('a network failure during refresh keeps the user signed in', () async {
    final (api, session, _) = await signedIn((req) async {
      if (req.url.path == '/v1/auth/refresh') throw http.ClientException('offline');
      return json(401, {'error': {'code': 'unauthorized'}});
    });
    await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
    expect(session.signedIn, isTrue);
  });

  test('a rejected refresh token signs out but keeps the language setting', () async {
    final (api, session, storage) = await signedIn((req) async => json(401, {'error': {'code': 'unauthorized'}}));
    await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
    expect(session.signedIn, isFalse);
    expect(storage.data['app.locale'], 'en');
  });

  test('an HTML error page becomes a clean ApiException', () async {
    final (api, _, _) = await signedIn((req) async => http.Response('<html>Bad gateway</html>', 502));
    await expectLater(api.get('/services'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'http_502')));
  });
}
