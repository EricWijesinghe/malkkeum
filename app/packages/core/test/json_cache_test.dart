import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal in-memory keystore for this test only.
class _MemStorage extends FlutterSecureStorage {
  _MemStorage([Map<String, String>? initial]) : data = {...?initial};
  final Map<String, String> data;

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async =>
      data[key];

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }
}

void main() {
  test('round-trips a snapshot under the cache prefix', () async {
    final storage = _MemStorage();
    final cache = JsonCache(storage: storage);

    await cache.write('feed.guest', [
      {'kind': 'seasonal'},
    ]);

    expect(storage.data.keys, ['cache.feed.guest']);
    expect(await cache.read('feed.guest'), [
      {'kind': 'seasonal'},
    ]);
  });

  test('a corrupt snapshot reads as a cold start, not an error', () async {
    final cache = JsonCache(storage: _MemStorage({'cache.services': '{not json'}));

    expect(await cache.read('services'), isNull);
  });

  test('a missing key reads as null', () async {
    expect(await JsonCache(storage: _MemStorage()).read('feed.me'), isNull);
  });

  test('clear removes only the named snapshot', () async {
    final storage = _MemStorage({'cache.feed.me': '[]', 'cache.services': '[]'});

    await JsonCache(storage: storage).clear('feed.me');

    expect(storage.data.keys, ['cache.services']);
  });
}
