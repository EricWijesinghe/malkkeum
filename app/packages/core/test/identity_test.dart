import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryStorage extends FlutterSecureStorage {
  _MemoryStorage();
  final data = <String, String>{};

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data[key];

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async =>
      value == null ? data.remove(key) : data[key] = value;

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data.remove(key);
}

Future<ApiClient> _api(http.Response Function(http.Request) handler) async {
  final storage = _MemoryStorage();
  final session = Session(namespace: 'id', storage: storage);
  await session.save({'access_token': 'a', 'refresh_token': 'r', 'role': 'customer', 'subject': 'u1'});
  storage.data['app.locale'] = 'en';
  return ApiClient(baseUrl: 'http://x', session: session, client: MockClient((r) async => handler(r)));
}

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

void main() {
  test('identity id is read from the redirect; cancel or empty reads as null', () {
    expect(identityIdFromRedirect(Uri.parse('https://x/pay/identity-done.html?identityVerificationId=dev%3Aabc')), 'dev:abc');
    expect(identityIdFromRedirect(Uri.parse('https://x/pay/identity-done.html?code=USER_CANCEL')), isNull);
    expect(identityIdFromRedirect(Uri.parse('https://x/pay/identity-done.html?identityVerificationId=')), isNull);
  });

  test('availability follows the server setup flag', () async {
    final off = await _api((_) => _json({'enabled': false}));
    expect(await identityAvailable(off), isFalse);

    final on = await _api((r) {
      expect(r.url.path, '/v1/me/identity/setup');
      return _json({'enabled': true});
    });
    // Web and Windows builds have no WebView, so the server flag alone is not enough there.
    expect(await identityAvailable(on), !isWindowsApp());
  });

  test('a failed setup read hides the action', () async {
    final api = await _api((_) => http.Response('boom', 500));
    expect(await identityAvailable(api), isFalse);
  });
}
