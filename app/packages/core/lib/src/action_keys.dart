import 'dart:convert';

import 'api.dart';

/// Open keys per client: action (path + body) -> Idempotency-Key.
final _open = Expando<Map<String, String>>();

/// True when the server gave an answer it will replay for this key; false when the reply was lost
/// or the server could not finish (network, timeout, 5xx, still running), so a retry must reuse it.
bool isFinalAnswer(ApiException e) =>
    !e.isNetwork && e.status < 500 && e.code != 'idempotency_in_progress';

extension ActionKeys on ApiClient {
  /// POST for one user action (pay, cancel, accept, review). The action is the path plus body, so a
  /// retry or second tap of the same action sends the same Idempotency-Key and the server replays
  /// the first answer instead of charging or booking twice; a changed draft is a new action.
  /// The key is dropped once the server answered for good.
  Future<dynamic> postAction(String path, Object? body) async {
    final open = _open[this] ??= {};
    final action = '$path ${jsonEncode(body)}';
    final key = open.putIfAbsent(action, ApiClient.newIdempotencyKey);
    try {
      final r = await post(path, body, key);
      open.remove(action);
      return r;
    } on ApiException catch (e) {
      if (isFinalAnswer(e)) open.remove(action);
      rethrow;
    }
  }
}
