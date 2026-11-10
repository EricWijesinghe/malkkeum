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
