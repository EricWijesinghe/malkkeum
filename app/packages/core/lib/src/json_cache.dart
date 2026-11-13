import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Last-good JSON snapshots (feed, catalogue) so screens paint at once on start, then refresh.
/// Best effort by design: a failed read or write just means a cold start, never a wrong screen.
class JsonCache {
  JsonCache({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _k(String key) => 'cache.$key';

  Future<Object?> read(String key) async {
    try {
      final raw = await _storage.read(key: _k(key));
      return raw == null ? null : jsonDecode(raw);
    } on Object {
      // Unreadable or corrupt snapshot: treat as a cold start.
      return null;
    }
  }

  /// Forgets one snapshot (sign-out, a finished booking).
  Future<void> clear(String key) async {
    try {
      await _storage.delete(key: _k(key));
    } on Object {
      // A snapshot that survives only costs a cold start on the next launch.
    }
  }

  /// Forgets one snapshot (sign-out, a finished booking).
  Future<void> clear(String key) async {
    try {
      await _storage.delete(key: _k(key));
    } on Object {
      // A snapshot that survives only costs a cold start on the next launch.
    }
  }

  Future<void> write(String key, Object value) async {
    try {
      await _storage.write(key: _k(key), value: jsonEncode(value));
    } on Object {
      // Losing the snapshot only costs speed on the next start.
    }
  }
}
