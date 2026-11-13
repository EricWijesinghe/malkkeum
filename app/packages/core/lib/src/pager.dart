import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'async_view.dart';
import 'i18n.dart';
import 'models.dart';

/// Rows of a cursor list (`X-Next-Cursor`), a page at a time. [first] starts over (load / pull to
/// refresh); [more] appends the next page. A failed [more] stops paging until the next [first].
class Pager<T> {
  Pager(this.api, this.path, this.parse, {this.query});

  final ApiClient api;
  final String path;
  final T Function(Json row) parse;
  /// Read on every [first], so a list with filters pages under the filters it was loaded with.
  final Map<String, String?> Function()? query;
  Map<String, String?>? _query;

  List<T> rows = const [];
  String? _next;
  int _gen = 0;
  bool _busy = false;
  bool _failed = false;

  bool get hasMore => _next != null && !_failed;

  Future<List<T>> first() async {
    final gen = ++_gen;
    final q = query?.call();
    final page = await api.getPage(path, query: q);
    if (gen == _gen) {
      rows = _parse(page.items);
      _query = q;
      _next = page.next;
      _failed = false;
    }
    return rows;
  }

  /// The next page; false when there is none, one is already loading, or a [first] overtook it.
  Future<bool> more() async {
    if (!hasMore || _busy) return false;
    final gen = _gen;
    _busy = true;
    try {
      final page = await api.getPage(path, query: _query, cursor: _next);
      if (gen != _gen) return false;
      rows = [...rows, ..._parse(page.items)];
      _next = page.next;
      return true;
    } catch (_) {
      _failed = true;
      rethrow;
    } finally {
      _busy = false;
    }
  }

  List<T> _parse(List<dynamic> items) => [
    for (final e in items) parse(e as Json),
  ];
}

/// Wraps a list's scroll view: near its end the next page of [pager] loads and [builder] runs again
/// with the longer list. Put it inside the `AsyncView` builder whose `load` is `pager.first`.
class LoadMore<T> extends StatefulWidget {
  const LoadMore({super.key, required this.pager, required this.builder});

  final Pager<T> pager;
  final Widget Function(BuildContext context, List<T> rows) builder;

  @override
  State<LoadMore<T>> createState() => _LoadMoreState<T>();
}

class _LoadMoreState<T> extends State<LoadMore<T>> {
  /// Start the next page this far (logical px) before the end, so scrolling rarely waits.
  static const _ahead = 600.0;

  bool _onScroll(Notification n) {
    final metrics = switch (n) {
      ScrollNotification(:final metrics) when n.depth == 0 => metrics,
      // Also fires after layout, so a first page shorter than the screen still fetches the next one.
      ScrollMetricsNotification(:final metrics) when n.depth == 0 => metrics,
      _ => null,
    };
    if (metrics != null &&
        metrics.axis == Axis.vertical &&
        metrics.extentAfter < _ahead &&
        widget.pager.hasMore) {
      _more();
    }
    return false;
  }

  Future<void> _more() async {
    try {
      if (await widget.pager.more() && mounted) setState(() {});
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) => NotificationListener<Notification>(
    onNotification: _onScroll,
    child: widget.builder(context, widget.pager.rows),
  );
}

/// [AsyncView] over a cursor list that loads more rows on scroll; for screens with no state of their own.
class PagedView<T> extends StatefulWidget {
  const PagedView({
    super.key,
    required this.api,
    required this.path,
    required this.parse,
    required this.builder,
  });

  final ApiClient api;
  final String path;
  final T Function(Json row) parse;
  final Widget Function(
    BuildContext context,
    List<T> rows,
    Future<void> Function() reload,
  )
  builder;

  @override
  State<PagedView<T>> createState() => _PagedViewState<T>();
}

class _PagedViewState<T> extends State<PagedView<T>> {
  late final _pager = Pager<T>(widget.api, widget.path, widget.parse);

  @override
  Widget build(BuildContext context) => AsyncView<List<T>>(
    load: _pager.first,
    builder: (context, _, reload) => LoadMore<T>(
      pager: _pager,
      builder: (context, rows) => widget.builder(context, rows, reload),
    ),
  );
}
