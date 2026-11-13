import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'i18n.dart';

/// Loads once, shows skeletons, a friendly error with retry, then content.
/// Once content is on screen a failed reload keeps it and shows a toast (needs a Scaffold above),
/// at most one per [toastGap] per view, so a screen reloading on every event while offline stays quiet.
/// Call [AsyncViewState.reload] (via GlobalKey or `onRefresh`) to refetch.
class AsyncView<V> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.skeletons = 3,
    this.skeletonHeight = 88,
  });

  final Future<V> Function() load;
  final Widget Function(
    BuildContext context,
    V value,
    Future<void> Function() reload,
  )
  builder;
  final int skeletons;
  final double skeletonHeight;

  @override
  State<AsyncView<V>> createState() => AsyncViewState<V>();
}

class AsyncViewState<V> extends State<AsyncView<V>> {
  static const toastGap = Duration(seconds: 30);

  late Future<V> _future = widget.load();
  V? _last;

  /// Running while a failed-reload toast was shown less than [toastGap] ago.
  Timer? _toastQuiet;

  @override
  void dispose() {
    _toastQuiet?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    final f = widget.load();
    setState(() {
      _future = f;
    });
    try {
      await f;
    } catch (e) {
      // With nothing loaded yet the error state renders below. With data on screen it stays, so say why.
      if (mounted && _last != null && _toastQuiet == null) {
        showToast(context, context.t.error(e));
        _toastQuiet = Timer(toastGap, () => _toastQuiet = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<V>(
    future: _future,
    builder: (context, snap) {
      if (snap.hasData) {
        _last = snap.data;
        return widget.builder(context, snap.data as V, reload);
      }
      // Keep the previous data while refreshing (no flash of skeletons) and when a refresh fails
      // (pull-to-refresh with no signal must not swap a full list for an error page).
      if (_last != null) return widget.builder(context, _last as V, reload);
      if (snap.hasError) {
        return ErrorRetry(
          message: context.t.error(snap.error!),
          retryLabel: context.t.retry,
          onRetry: reload,
        );
      }
      // A Column, not a ListView: callers may sit this inside their own scroll view.
      return Padding(
        padding: const EdgeInsets.all(Space.gutter),
        child: Column(
          children: [
            for (var i = 0; i < widget.skeletons; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Skeleton(height: widget.skeletonHeight),
              ),
          ],
        ),
      );
    },
  );
}
