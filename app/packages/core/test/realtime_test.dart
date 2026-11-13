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
class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.uri);
  final Uri uri;
  final _in = StreamController<dynamic>();
  bool closed = false;

  @override
  Stream<dynamic> get stream => _in.stream;

  @override
  Future<void> get ready => Future.value();

  @override
  WebSocketSink get sink => _FakeSink(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
}
