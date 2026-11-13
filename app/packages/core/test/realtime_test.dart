import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _MemStorage extends FlutterSecureStorage {
  final data = <String, String>{};

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

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data.remove(key);
}

/// A socket that stays open until closed; records its URL and whether it was closed.
/// [offline]: the connection fails the way it does with no signal.
class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.uri, {this.offline = false}) {
    if (offline) _in.addError(const SocketExceptionStub());
  }
  final Uri uri;
  final bool offline;
  final _in = StreamController<dynamic>();
  bool closed = false;

  @override
  Stream<dynamic> get stream => _in.stream;

  @override
  Future<void> get ready => offline ? Future.error(const SocketExceptionStub()) : Future.value();

  @override
  WebSocketSink get sink => _FakeSink(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this.ch);
  final _FakeChannel ch;

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    ch.closed = true;
    await ch._in.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Session session;
  late List<_FakeChannel> opened;
  late Realtime rt;
  late List<String> events;

  setUp(() async {
    session = Session(namespace: 't', storage: _MemStorage());
    final api = ApiClient(
      baseUrl: 'http://api.test',
      session: session,
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    await session.save({'access_token': 'a1', 'refresh_token': 'r1', 'role': 'customer', 'subject': 'u1'});
    opened = [];
    rt = Realtime(api, connector: (uri) => (opened..add(_FakeChannel(uri))).last);
    events = [];
    rt.events.listen((e) => events.add(e['type'] as String));
  });

  tearDown(() => rt.dispose());

  test('reconnect replaces the socket and asks screens to refetch', () async {
    rt.connect();
    expect(opened, hasLength(1));
    rt.reconnect();
    await pumpEventQueue();
    expect(opened.first.closed, isTrue);
    expect(opened, hasLength(2));
    expect(opened.last.closed, isFalse);
    expect(events, ['resync']);
  });

  test('reconnect does nothing while signed out or never connected', () async {
    rt.reconnect();
    expect(opened, isEmpty);
    rt.connect();
    await session.clear();
    rt.reconnect();
    await pumpEventQueue();
    expect(opened, hasLength(1));
    expect(opened.single.closed, isTrue, reason: 'sign-out closes the socket');
    expect(events, isEmpty);
  });

  test('a new sign-in after sign-out opens a socket for the new account when connected again', () async {
    rt.connect();
    await session.clear();
    await session.save({'access_token': 'b1', 'refresh_token': 'r2', 'role': 'customer', 'subject': 'u2'});
    expect(opened, hasLength(1), reason: 'the app decides when the next account goes live');
    rt.connect();
    expect(opened, hasLength(2));
    expect(opened.last.uri.queryParameters['token'], 'b1');
  });

  testWidgets('a socket that comes back after failed tries asks screens to refetch again', (tester) async {
    var offline = true;
    final sockets = <_FakeChannel>[];
    final types = <String>[];
    final live = Realtime(
      ApiClient(baseUrl: 'http://api.test', session: session, client: MockClient((_) async => http.Response('[]', 200))),
      connector: (uri) => (sockets..add(_FakeChannel(uri, offline: offline))).last,
    );
    final sub = live.events.listen((e) => types.add(e['type'] as String));
    live.connect();
    await tester.pump();
    expect(types, ['resync'], reason: 'the drop asks for a refetch (it fails while offline)');

    offline = false;
    await tester.pump(const Duration(seconds: 3)); // first backoff is 1-2 s
    await tester.pump();
    expect(sockets, hasLength(2));
    expect(types, ['resync', 'resync'], reason: 'connected again: refetch now that it can work');

    live.reconnect();
    await tester.pump();
    expect(types, ['resync', 'resync', 'resync'], reason: 'a resume asks once, not twice');
    await sub.cancel();
    live.dispose();
  });
}
