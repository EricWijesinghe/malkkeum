import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';

/// Live server events with automatic reconnect (exponential backoff + jitter).
class Realtime {
  Realtime(this.api);
  final ApiClient api;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _ch;
  StreamSubscription<dynamic>? _sub;
  Timer? _retry;
  int _attempt = 0;
  bool _wanted = false;

  Stream<Map<String, dynamic>> get events => _events.stream;
  Stream<Map<String, dynamic>> on(String type) => events.where((e) => e['type'] == type || e['type'] == 'resync');

  void connect() {
    _wanted = true;
    _open();
  }

  void _open() {
    if (!_wanted || _ch != null || api.session.accessToken == null) {
      if (_wanted && api.session.accessToken == null) _schedule();
      return;
    }
    try {
      final ch = WebSocketChannel.connect(api.wsUri());
      _ch = ch;
      _sub = ch.stream.listen(
        (raw) {
          _attempt = 0;
          final decoded = jsonDecode(raw as String);
          if (decoded is Map<String, dynamic>) _events.add(decoded);
        },
        onDone: _dropped,
        onError: (_) => _dropped(),
        cancelOnError: true,
      );
    } catch (_) {
      _dropped();
    }
  }

  void _dropped() {
    _sub?.cancel();
    _ch = null;
    _sub = null;
    // After a drop the client may have missed events: tell listeners to refetch.
    _events.add({'type': 'resync'});
    _schedule();
  }

  void _schedule() {
    if (!_wanted) return;
    _retry?.cancel();
    final seconds = min(30, pow(2, _attempt).toInt()) + Random().nextDouble();
    _attempt++;
    _retry = Timer(Duration(milliseconds: (seconds * 1000).round()), () async {
      // Access tokens are short-lived; a cheap authenticated call refreshes it if needed.
      try {
        await api.get('/me/notifications');
      } catch (_) {}
      _open();
    });
  }

  void disconnect() {
    _wanted = false;
    _retry?.cancel();
    _sub?.cancel();
    _ch?.sink.close();
    _ch = null;
  }
}
