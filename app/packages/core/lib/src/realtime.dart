import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';

/// Live server events with automatic reconnect (exponential backoff + jitter).
/// Follows the session: signing out closes the socket, so one person's events can
/// never reach the next person who signs in on the same device.
class Realtime {
  Realtime(this.api, {WebSocketChannel Function(Uri uri)? connector})
    : _connect = connector ?? WebSocketChannel.connect {
    api.session.addListener(_onSession);
  }

  final ApiClient api;
  final WebSocketChannel Function(Uri uri) _connect;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _ch;
  StreamSubscription<dynamic>? _sub;
  Timer? _retry;
  int _attempt = 0;
  bool _wanted = false;
  String? _subject;

  /// Bumped on every close: a ticket that comes back for an older generation is dropped unused.
  int _generation = 0;

  static const _maxBackoffSeconds = 30;

  Stream<Map<String, dynamic>> get events => _events.stream;

  /// Events of [type], plus `resync` (sent after any gap so screens refetch).
  Stream<Map<String, dynamic>> on(String type) =>
      events.where((e) => e['type'] == type || e['type'] == 'resync');

  void connect() {
    _wanted = true;
    _subject = api.session.subject;
    _open();
  }

  /// Closes and reopens the socket, and tells listeners to refetch. For app resume: after a long
  /// background or a network switch the socket can be half-open (looks connected, delivers nothing),
  /// and the client cannot see the server's pings. Does nothing while not connected on purpose.
  void reconnect() {
    if (!_wanted) return;
    _close();
    _attempt = 0;
    _events.add({'type': 'resync'});
    _open();
  }

  void _onSession() {
    if (!api.session.signedIn) {
      disconnect();
    } else if (_wanted && api.session.subject != _subject) {
      // A different account signed in: start a fresh socket under the new identity.
      _close();
      connect();
    }
  }

  void _open() {
    if (!_wanted || _ch != null) return;
    if (api.session.accessToken == null) return _schedule();
    unawaited(_openWithTicket(_generation));
  }

  /// Each connect spends a fresh single-use ticket, so the access token never reaches a URL. A 401 on
  /// the ticket call refreshes the session inside [ApiClient] (one retry); if that still fails, back off.
  Future<void> _openWithTicket(int generation) async {
    final Uri uri;
    try {
      uri = await api.wsUri();
    } catch (_) {
      if (generation == _generation) _dropped();
      return;
    }
    // Closed or re-opened while the ticket was in flight: this ticket is for a socket nobody wants.
    if (generation != _generation || !_wanted || _ch != null) return;
    _dial(uri);
  }

  void _dial(Uri uri) {
    try {
      final ch = _connect(uri);
      _ch = ch;
      ch.ready.then((_) {
        // Back after failed tries (no signal, server restart): the refetch sent when the socket
        // dropped may itself have failed offline, so ask screens again now that the link works.
        if (_attempt > 0 && identical(_ch, ch)) _events.add({'type': 'resync'});
        _attempt = 0;
      }, onError: (Object _) {});
      _sub = ch.stream.listen(
        _onFrame,
        onDone: _dropped,
        onError: (Object _) => _dropped(),
        cancelOnError: true,
      );
    } catch (_) {
      _dropped();
    }
  }

  void _onFrame(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is Map<String, dynamic>) _events.add(decoded);
    } catch (_) {
      // Ignore malformed frames rather than killing the stream.
    }
  }

  void _dropped() {
    _close();
    if (!_wanted) return;
    // The client may have missed events while disconnected: tell listeners to refetch.
    _events.add({'type': 'resync'});
    _schedule();
  }

  void _schedule() {
    if (!_wanted) return;
    _retry?.cancel();
    final seconds =
        min(_maxBackoffSeconds, pow(2, _attempt).toInt()) +
        Random().nextDouble();
    _attempt++;
    _retry = Timer(Duration(milliseconds: (seconds * 1000).round()), () async {
      // Access tokens are short-lived; a cheap authenticated call refreshes it if needed.
      try {
        await api.get('/me/notifications');
      } catch (_) {
        // Offline or signed out; the next attempt (or a sign-out) decides.
      }
      _open();
    });
  }

  void _close() {
    _generation++;
    _retry?.cancel();
    _sub?.cancel();
    _ch?.sink.close();
    _ch = null;
    _sub = null;
  }

  void disconnect() {
    _wanted = false;
    _attempt = 0;
    _close();
  }

  void dispose() {
    disconnect();
    api.session.removeListener(_onSession);
    _events.close();
  }
}
