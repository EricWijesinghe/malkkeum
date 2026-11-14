import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Minimal in-memory keystore for this test only.
class _MemStorage extends FlutterSecureStorage {
  _MemStorage([Map<String, String>? initial]) : data = {...?initial};
  final Map<String, String> data;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }
}

const _apiBase = 'https://api.test';

/// The shape `GET /v1/brand` really returns (see `sign_json` in backend uploads.rs).
const _logo =
    '/v1/files/0123456789abcdef0123456789abcdef.png?exp=1793000000&sig=ab12cd34';

BrandController _controller({
  required http.Client http_,
  _MemStorage? storage,
}) {
  final api = ApiClient(
    baseUrl: _apiBase,
    session: Session(namespace: 'brand-test', storage: _MemStorage()),
    client: http_,
  );
  return BrandController(
    api: api,
    fallback: BrandConfig.placeholder,
    cache: JsonCache(storage: storage ?? _MemStorage()),
  );
}

http.Client _profile(Map<String, Object?> body, {List<String>? seen}) =>
    MockClient((req) async {
      seen?.add(req.url.path);
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

http.Client _offline() =>
    MockClient((_) async => throw http.ClientException('offline'));

void main() {
  group('brandFromProfile', () {
    BrandConfig parse(Map<String, Object?> p) => brandFromProfile(
      p,
      fallback: BrandConfig.placeholder,
      apiBase: _apiBase,
    );

    test('a valid dark colour becomes the primary, with derived pressed and brand shades', () {
      final b = parse({'primary_color': '#0B5D2A', 'name': ' 새 가게 '});

      expect(b.primary, const Color(0xFF0B5D2A));
      expect(
        b.primaryDeep.computeLuminance(),
        lessThan(b.primary.computeLuminance()),
      );
      expect(b.name, '새 가게');
      expect(b.sun, BrandConfig.placeholder.sun);
    });

    test(
      'a colour too light for white label text keeps the built-in brand',
      () {
        final b = parse({'primary_color': '#FFD95A'});

        expect(b.primary, BrandConfig.placeholder.primary);
        expect(b.primaryDeep, BrandConfig.placeholder.primaryDeep);
      },
    );

    test('malformed colours and empty names fall back', () {
      for (final bad in ['blue', '#12345', '0B5D2A', 42, null]) {
        final b = parse({'primary_color': bad, 'name': '   '});
        expect(b.primary, BrandConfig.placeholder.primary, reason: '$bad');
        expect(b.name, BrandConfig.placeholder.name, reason: '$bad');
      }
    });

    test(
      'a signed upload URL from the API becomes the logo URL, query included',
      () {
        expect(
          parse({'logo_url': '$_apiBase$_logo'}).logoUrl,
          '$_apiBase$_logo',
        );
      },
    );

    test('only signed upload URLs on the API origin become logo URLs', () {
      const hex = '0123456789abcdef0123456789abcdef';
      for (final bad in [
        _logo, // relative: the API never sends this form
        '/files/$hex.png',
        '/v1/files/../etc/passwd?exp=1&sig=ab',
        '/v1/files/$hex.png', // unsigned
        '/v1/files/$hex.svg?exp=1&sig=ab',
        '/v1/files/$hex.heic?exp=1&sig=ab',
        'https://evil.test/v1/files/$hex.png?exp=1&sig=ab',
        'https://api.test.evil.test/v1/files/$hex.png?exp=1&sig=ab',
      ]) {
        expect(parse({'logo_url': bad}).logoUrl, isNull, reason: bad);
      }
    });
  });

  test('restore applies the saved brand before any network call', () async {
    final storage = _MemStorage({
      'cache.brand': jsonEncode({'primary_color': '#0B5D2A', 'name': '저장된 가게'}),
    });
    final c = _controller(http_: _offline(), storage: storage);

    await c.restore();

    expect(c.brand.primary, const Color(0xFF0B5D2A));
    expect(c.brand.name, '저장된 가게');
  });

  test('a corrupt snapshot reads as no snapshot', () async {
    final c = _controller(
      http_: _offline(),
      storage: _MemStorage({'cache.brand': '{not json'}),
    );

    await c.restore();

    expect(c.brand.primary, BrandConfig.placeholder.primary);
  });

  test(
    'refresh saves only the brand fields and notifies once per change',
    () async {
      final storage = _MemStorage();
      final seen = <String>[];
      final c = _controller(
        http_: _profile({
          'name': '다해',
          'primary_color': '#0B5D2A',
          'logo_url': '$_apiBase$_logo',
          'legal_name': 'must not be cached',
          'ceo': 'must not be cached',
        }, seen: seen),
        storage: storage,
      );
      var notified = 0;
      c.addListener(() => notified++);

      await c.refresh();
      await c.refresh();

      expect(seen, ['/v1/brand', '/v1/brand']);
      expect(notified, 1);
      expect(c.brand.primary, const Color(0xFF0B5D2A));
      expect(c.brand.logoUrl, '$_apiBase$_logo');
      final cached =
          jsonDecode(storage.data['cache.brand']!) as Map<String, dynamic>;
      expect(cached.keys.toSet(), {'name', 'primary_color', 'logo_url'});
    },
  );

  test('offline refresh keeps the saved brand and does not throw', () async {
    final storage = _MemStorage({
      'cache.brand': jsonEncode({'primary_color': '#0B5D2A'}),
    });
    final c = _controller(http_: _offline(), storage: storage);
    await c.restore();

    await c.refresh();

    expect(c.brand.primary, const Color(0xFF0B5D2A));
  });

  test('offline with nothing saved paints the built-in brand', () async {
    final c = _controller(http_: _offline());

    await c.restore();
    await c.refresh();

    expect(c.brand.primary, BrandConfig.placeholder.primary);
    expect(c.brand.name, BrandConfig.placeholder.name);
  });
}
