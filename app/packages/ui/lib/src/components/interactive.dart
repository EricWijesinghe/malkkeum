import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';

/// Tactile press: the child springs down to [pressedScale] and its shadow
/// tightens while the pointer is held; release springs back with haptics.
///
/// Visual + haptic only when [onTap] is null (wrap a Material button). With
/// [onTap] it also fires on release, unless the pointer dragged past touch slop
/// (so scrolling a list over a card never counts as a tap).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.shadows = const [],
    this.radius = const BorderRadius.all(Radius.circular(Radii.card)),
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  /// Resting shadow; tightened (smaller blur and offset) while pressed.
  final List<BoxShadow> shadows;
  final BorderRadius radius;
  final double pressedScale;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 26,
  );

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  /// 0 = rest, 1 = fully pressed. Unbounded so the release spring can overshoot.
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
  );
  Offset? _down;
  bool _moved = false;

  bool get _live => widget.enabled && !MediaQuery.disableAnimationsOf(context);

  void _press(bool down) {
    if (!mounted) return;
    if (!_live || !down) {
      _c.animateWith(
        SpringSimulation(Pressable._spring, _c.value, 0, _c.velocity),
      );
    } else {
      _c.animateTo(1, duration: Motion.press, curve: Curves.easeOut);
    }
  }

  void _onDown(PointerDownEvent e) {
    if (!widget.enabled) return;
    _down = e.localPosition;
    _moved = false;
    _press(true);
  }

  void _onMove(PointerMoveEvent e) {
    final d = _down;
    if (d == null || _moved) return;
    if ((e.localPosition - d).distance > kTouchSlop) {
      _moved = true;
      _press(false);
    }
  }

  void _onUp(PointerUpEvent _) {
    final tap = _down != null && !_moved;
    _down = null;
    _press(false);
    if (tap && widget.onTap != null) {
      HapticFeedback.selectionClick();
      widget.onTap!();
    }
  }

  void _onCancel(PointerCancelEvent _) {
    _down = null;
    _press(false);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tight = [
      for (final s in widget.shadows)
        BoxShadow(
          color: s.color,
          offset: s.offset * 0.35,
          blurRadius: s.blurRadius * 0.45,
          spreadRadius: s.spreadRadius,
        ),
    ];
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.enabled,
      onTap: widget.enabled ? widget.onTap : null,
      child: Listener(
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final v = _c.value.clamp(0.0, 1.0);
            final scale = 1 - (1 - widget.pressedScale) * _c.value;
            return Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.radius,
                  boxShadow: BoxShadow.lerpList(widget.shadows, tight, v),
                ),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Perspective tilt that follows the pointer (hover on desktop, drag on touch)
/// with a moving specular highlight, and springs flat on release. Static when
/// the OS asks for reduced motion.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.maxAngle = 0.12,
    this.radius = const BorderRadius.all(Radius.circular(Radii.card)),
  });

  final Widget child;

  /// Max rotation in radians (0.12 ~ 7 degrees).
  final double maxAngle;
  final BorderRadius radius;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 160,
    damping: 16,
  );

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with TickerProviderStateMixin {
  /// Normalised pointer position in [-1, 1]; 0 = rest.
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _y = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: Motion.standard,
  );

  bool get _live => !MediaQuery.disableAnimationsOf(context);

  void _track(Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty || !_live) return;
    _x.value = (local.dx / box.size.width * 2 - 1).clamp(-1.0, 1.0);
    _y.value = (local.dy / box.size.height * 2 - 1).clamp(-1.0, 1.0);
    _glow.forward();
  }

  void _release() {
    _glow.reverse();
    _x.animateWith(SpringSimulation(Tilt3D._spring, _x.value, 0, _x.velocity));
    _y.animateWith(SpringSimulation(Tilt3D._spring, _y.value, 0, _y.velocity));
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _glow.dispose();
    super.dispose();
  }

  // Reduced motion: no transform layer or pointer tracking at all.
  @override
  Widget build(BuildContext context) =>
      _live ? _tilted(context) : widget.child;

  Widget _tilted(BuildContext context) => MouseRegion(
    onEnter: (e) => _track(e.localPosition),
    onHover: (e) => _track(e.localPosition),
    onExit: (_) => _release(),
    child: Listener(
      onPointerDown: (e) => _track(e.localPosition),
      onPointerMove: (e) => _track(e.localPosition),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_x, _y, _glow]),
        child: widget.child,
        builder: (_, child) {
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-_y.value * widget.maxAngle)
            ..rotateY(_x.value * widget.maxAngle);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: Stack(
              children: [
                child!,
                if (_glow.value > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: widget.radius,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(_x.value, _y.value),
                              radius: 0.9,
                              colors: [
                                Colors.white.withValues(
                                  alpha: 0.20 * _glow.value,
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
