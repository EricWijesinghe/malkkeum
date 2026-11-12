/// First-touch campaign params from the URL the app was opened with (site links carry utm_* and ref).
/// Read once per app launch and sent with signup; the server stores the first value it receives and never
/// overwrites it. Nothing is written to cookies or storage.
abstract final class Attribution {
  static const keys = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term', 'ref'];
  static const _maxChars = 80;

  static Map<String, String>? _captured;
  static bool _read = false;

  /// The params of [uri] that the server accepts, or null when there are none.
  static Map<String, String>? fromUri(Uri uri) {
    final out = <String, String>{};
    for (final k in keys) {
      final v = uri.queryParameters[k]?.trim();
      if (v != null && v.isNotEmpty) out[k] = v.length > _maxChars ? v.substring(0, _maxChars) : v;
    }
    return out.isEmpty ? null : out;
  }

  /// Captured from `Uri.base` on the first call of this launch.
  static Map<String, String>? get() {
    if (!_read) {
      _read = true;
      _captured = fromUri(Uri.base);
    }
    return _captured;
  }
}
