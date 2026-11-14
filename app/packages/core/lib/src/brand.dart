import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'json_cache.dart';
import 'models.dart';

final _hexColour = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// `/brand` returns uploads signed by the API: `<base>/v1/files/<32 hex>.<ext>?exp=<n>&sig=<hex>`.
/// The signature lapses after 1-2 hours; an expired one fails to load and the mark falls back.
/// HEIC is left out: `Image.network` cannot decode it on every platform.
final _signedLogoPath = RegExp(
  r'^/v1/files/[0-9a-f]{32}\.(png|jpe?g|webp)\?exp=\d+&sig=[0-9a-f]+$',
);

/// The business-profile fields the apps use. Only these are cached, never the whole profile.
const _brandKeys = ['name', 'primary_color', 'logo_url'];
const brandCacheKey = 'brand';

/// The brand for a public profile (`GET /v1/brand`). A missing or unusable value keeps the [fallback] value.
/// A colour that fails the white-label-text contrast check is ignored, so a bad choice never hides a button label.
BrandConfig brandFromProfile(
  Json profile, {
  required BrandConfig fallback,
  required String apiBase,
}) {
  final colour = _brandColour(profile['primary_color']);
  final logo = profile['logo_url'];
  return BrandConfig(
    name: _text(profile['name']) ?? fallback.name,
    primary: colour ?? fallback.primary,
    primaryDeep: colour == null ? fallback.primaryDeep : _shade(colour, -0.12),
    fresh: colour == null ? fallback.fresh : _shade(colour, 0.12),
    sun: fallback.sun,
    ink: fallback.ink,
    logoUrl: _logoUrl(logo, apiBase) ?? fallback.logoUrl,
  );
}

/// Accepts only a signed upload URL on the API's own origin; anything else (foreign hosts, bare paths) is ignored.
String? _logoUrl(Object? v, String apiBase) {
  if (v is! String || !v.startsWith(apiBase)) return null;
  return _signedLogoPath.hasMatch(v.substring(apiBase.length)) ? v : null;
}

String? _text(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

Color? _brandColour(Object? v) {
  if (v is! String || !_hexColour.hasMatch(v)) return null;
  final c = Color(0xFF000000 | int.parse(v.substring(1), radix: 16));
  return whiteTextReadsOn(c) ? c : null;
}

Color _shade(Color c, double lightnessDelta) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + lightnessDelta).clamp(0.0, 1.0))
      .toColor();
}

Map<String, Object?> _pick(Json profile) => {
  for (final k in _brandKeys)
    if (profile[k] != null) k: profile[k],
};

/// Holds the brand the apps paint with. Starts from the saved profile (or [fallback]) so the first frame
/// already has the right colours, then [refresh] pulls the live profile. Offline, the last good brand stays.
class BrandController extends ChangeNotifier {
  BrandController({required this.api, required this.fallback, JsonCache? cache})
    : _cache = cache ?? JsonCache(),
      _brand = fallback;

  final ApiClient api;
  final BrandConfig fallback;
  final JsonCache _cache;
  BrandConfig _brand;
  Map<String, Object?> _saved = const {};

  BrandConfig get brand => _brand;

  /// Applies the saved profile, if any. A corrupt snapshot reads as no snapshot.
  Future<void> restore() async {
    final saved = await _cache.read(brandCacheKey);
    if (saved is Json) _apply(saved);
  }

  /// Fetches the public profile and saves its brand fields. An offline or failed call is not an error
  /// here: the brand is cosmetic, so the saved or built-in brand stays on screen.
  Future<void> refresh() async {
    final Object? body;
    try {
      body = await api.get('/brand');
    } on ApiException {
      return;
    }
    if (body is! Json) return;
    final saved = _pick(body);
    if (mapEquals(saved, _saved)) return;
    await _cache.write(brandCacheKey, saved);
    _apply(saved);
  }

  void _apply(Json profile) {
    _saved = _pick(profile);
    _brand = brandFromProfile(
      profile,
      fallback: fallback,
      apiBase: api.baseUrl,
    );
    notifyListeners();
  }
}
