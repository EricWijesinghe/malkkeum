import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ui/ui.dart';

import 'api_test.dart' show FakeStorage;

/// 120 rows served 50 per page, newest first, the way the backend's `paged()` does it.
const _total = 120;
const _page = 50;

(ApiClient, List<String?>) _api() {
  final cursors = <String?>[];
  final api = ApiClient(
    baseUrl: 'http://x',
    session: Session(namespace: 't', storage: FakeStorage()),
    client: MockClient((req) async {
      final cursor = req.url.queryParameters['cursor'];
      cursors.add(cursor);
      final from = cursor == null ? 0 : int.parse(cursor);
      final to = (from + _page).clamp(0, _total);
      return http.Response(
        jsonEncode([for (var i = from; i < to; i++) {'id': 'r$i'}]),
        200,
        headers: {
          'content-type': 'application/json',
          if (to < _total) 'x-next-cursor': '$to',
        },
      );
    }),
  );
  return (api, cursors);
}

Widget _app(Pager<String> pager, Widget Function(List<String> rows) list) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: T.localizationsDelegates,
  supportedLocales: T.supportedLocales,
  theme: buildTheme(BrandConfig.placeholder, Brightness.light),
  home: Scaffold(
    body: AsyncView<List<String>>(
      load: pager.first,
      builder: (context, _, _) => LoadMore<String>(pager: pager, builder: (context, rows) => list(rows)),
    ),
  ),
);

void main() {
  test('pages follow X-Next-Cursor until the header stops; first() starts over', () async {
    final (api, cursors) = _api();
    final pager = Pager<String>(api, '/things', (j) => j['id'] as String);

    expect(await pager.first(), hasLength(50));
    expect(pager.hasMore, isTrue);
    expect(await pager.more(), isTrue);
    expect(await pager.more(), isTrue);
    expect(pager.rows, hasLength(_total));
    expect(pager.rows.last, 'r119');
    expect(pager.hasMore, isFalse);
    expect(await pager.more(), isFalse, reason: 'no request past the last page');
    expect(cursors, [null, '50', '100']);

    await pager.first();
    expect(pager.rows, hasLength(50));
    expect(pager.hasMore, isTrue);
  });

  testWidgets('LoadMore fetches the next page when the list is scrolled to its end', (tester) async {
    final (api, cursors) = _api();
    final pager = Pager<String>(api, '/things', (j) => j['id'] as String);
    await tester.pumpWidget(
      _app(pager, (rows) => ListView(children: [for (final r in rows) SizedBox(height: 80, child: Text(r))])),
    );
    await tester.pump();
    await tester.pump();
    expect(cursors, [null], reason: 'a full first page does not fetch more on its own');

    await tester.dragUntilVisible(find.text('r119'), find.byType(ListView), const Offset(0, -2000));
    expect(find.text('r119'), findsOneWidget);
    expect(cursors, [null, '50', '100']);
  });

  testWidgets('a first page shorter than the screen still loads the next one', (tester) async {
    final cursors = <String?>[];
    final api = ApiClient(
      baseUrl: 'http://x',
      session: Session(namespace: 't', storage: FakeStorage()),
      client: MockClient((req) async {
        final cursor = req.url.queryParameters['cursor'];
        cursors.add(cursor);
        return http.Response(
          jsonEncode([{'id': cursor ?? 'first'}]),
          200,
          headers: {'content-type': 'application/json', if (cursor == null) 'x-next-cursor': 'second'},
        );
      }),
    );
    final pager = Pager<String>(api, '/things', (j) => j['id'] as String);
    await tester.pumpWidget(_app(pager, (rows) => ListView(children: [for (final r in rows) Text(r)])));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cursors, [null, 'second']);
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('a failed next page shows a retry row, and the retry loads that page', (tester) async {
    final cursors = <String?>[];
    var failNext = true;
    final api = ApiClient(
      baseUrl: 'http://x',
      session: Session(namespace: 't', storage: FakeStorage()),
      client: MockClient((req) async {
        final cursor = req.url.queryParameters['cursor'];
        cursors.add(cursor);
        if (cursor == '50' && failNext) {
          failNext = false;
          throw const SocketExceptionStub();
        }
        final from = cursor == null ? 0 : int.parse(cursor);
        final to = (from + _page).clamp(0, _total);
        return http.Response(
          jsonEncode([for (var i = from; i < to; i++) {'id': 'r$i'}]),
          200,
          headers: {'content-type': 'application/json', if (to < _total) 'x-next-cursor': '$to'},
        );
      }),
    );
    final pager = Pager<String>(api, '/things', (j) => j['id'] as String);
    await tester.pumpWidget(
      _app(pager, (rows) => ListView(children: [for (final r in rows) SizedBox(height: 80, child: Text(r))])),
    );
    await tester.pump();
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorRetry), findsOneWidget);
    expect(cursors, [null, '50']);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(cursors, [null, '50'], reason: 'a failed page does not retry on scroll alone');

    await tester.tap(find.descendant(of: find.byType(ErrorRetry), matching: find.byType(TextButton)));
    await tester.pump();
    await tester.pump();
    expect(cursors, [null, '50', '50']);
    expect(find.byType(ErrorRetry), findsNothing);

    await tester.dragUntilVisible(find.text('r119'), find.byType(ListView), const Offset(0, -2000));
    expect(find.text('r119'), findsOneWidget);
  });

  testWidgets('a loader shows under the list while the next page loads', (tester) async {
    final gate = Completer<void>();
    final cursors = <String?>[];
    final api = ApiClient(
      baseUrl: 'http://x',
      session: Session(namespace: 't', storage: FakeStorage()),
      client: MockClient((req) async {
        final cursor = req.url.queryParameters['cursor'];
        cursors.add(cursor);
        if (cursor != null) await gate.future;
        final from = cursor == null ? 0 : int.parse(cursor);
        final to = (from + _page).clamp(0, _total);
        return http.Response(
          jsonEncode([for (var i = from; i < to; i++) {'id': 'r$i'}]),
          200,
          headers: {'content-type': 'application/json', if (to < _total) 'x-next-cursor': '$to'},
        );
      }),
    );
    final pager = Pager<String>(api, '/things', (j) => j['id'] as String);
    await tester.pumpWidget(
      _app(pager, (rows) => ListView(children: [for (final r in rows) SizedBox(height: 80, child: Text(r))])),
    );
    await tester.pump();
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(cursors, [null, '50']);
  });

  testWidgets('the end of the list makes no further requests', (tester) async {
    final (api, cursors) = _api();
    final pager = Pager<String>(api, '/things', (j) => j['id'] as String);
    await tester.pumpWidget(
      _app(pager, (rows) => ListView(children: [for (final r in rows) SizedBox(height: 80, child: Text(r))])),
    );
    await tester.pump();
    await tester.pump();
    await tester.dragUntilVisible(find.text('r119'), find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(cursors, [null, '50', '100']);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.pump();
    expect(cursors, [null, '50', '100'], reason: 'no request past the last page');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ErrorRetry), findsNothing);
  });
}

/// Stands in for a dropped connection; the client maps any thrown error to a network failure.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
