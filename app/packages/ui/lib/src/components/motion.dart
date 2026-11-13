import 'package:flutter/material.dart';

import '../tokens.dart';

/// Horizontal shared-axis route: incoming page fades in while sliding 4% along
/// the x axis. Instant when the OS asks for reduced motion.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.emphasized,
      reverseCurve: Motion.ease,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Subtle 3D route: incoming page turns in around the Y axis (about 7 degrees),
/// scales from 96% and fades in. Pop runs the same curve in reverse.
/// Instant when the OS asks for reduced motion.
class Depth3DPageTransitionsBuilder extends PageTransitionsBuilder {
  const Depth3DPageTransitionsBuilder();

  static const _turn = 0.12;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.emphasized,
      reverseCurve: Motion.ease,
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (_, child) {
          final t = curved.value;
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY((1 - t) * _turn);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          );
        },
      ),
    );
  }
}

/// Staggered entrance for list sections and feed cards: each item fades and
/// rises after `index * step`, capped so long lists don't wait forever.
class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 45),
  });

  final int index;
  final Widget child;
  final Duration step;

  static const _maxSteps = 8;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.route,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    final delay = widget.step * widget.index.clamp(0, StaggerIn._maxSteps);
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Motion.emphasized);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 14 * (1 - curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Material fade-through for content that swaps in place (segment, tab or
/// filter results): the old child fades out over [Motion.fadeOut], then the
/// new one fades in over [Motion.fadeIn] while scaling 0.98 -> 1. Key each
/// child by what it shows (e.g. `KeyedSubtree(key: ValueKey(filter), ...)`),
/// or the swap is not detected. Reduced motion swaps at once.
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;

  /// Where old and new content line up during the swap.
  final AlignmentGeometry alignment;

  static const _scaleIn = 0.98;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final total = Motion.fadeOut + Motion.fadeIn;
    // The incoming child waits out the fade-out share of the total duration.
    final wait = Motion.fadeOut.inMicroseconds / total.inMicroseconds;
    return AnimatedSwitcher(
      duration: still ? Duration.zero : total,
      reverseDuration: still ? Duration.zero : Motion.fadeOut,
      switchInCurve: Interval(wait, 1, curve: Motion.ease),
      switchOutCurve: Curves.linear,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: _scaleIn, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
