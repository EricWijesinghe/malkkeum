import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// One-shot 3D flip-in for a hero moment (booking confirmed): the child turns
/// from edge-on to face-on around the Y axis while it fades up. Plays once on
/// first build, then holds at rest. Reduced motion shows the child at rest.
class FlipIn extends StatefulWidget {
  const FlipIn({super.key, required this.child});
  final Widget child;

  @override
  State<FlipIn> createState() => _FlipInState();
}

class _FlipInState extends State<FlipIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.celebrate + const Duration(milliseconds: 280),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Motion.emphasized);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: curved,
        child: widget.child,
        builder: (_, child) {
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(math.pi / 2 * (1 - curved.value));
          return Opacity(
            opacity: curved.value.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: m,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
