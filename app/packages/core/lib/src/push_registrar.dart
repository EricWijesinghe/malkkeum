import 'api.dart';

/// Keeps this device's push token registered to the signed-in account (/v1/me/push-token).
class PushRegistrar {
  PushRegistrar({required this.api, required this.platform});

  final ApiClient api;

  /// `android` or `ios` (the backend also accepts `windows` and `web`).
  final String platform;
  String? _token;

  String? get token => _token;

  Future<void> register(String token) async {
    await api.post('/me/push-token', {'token': token, 'platform': platform});
    _token = token;
  }

  /// Stops pushes to this device for the account. No-op when nothing was registered.
  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    await api.delete('/me/push-token', {'token': token});
    _token = null;
  }
}
