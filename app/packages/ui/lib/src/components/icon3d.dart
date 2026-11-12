import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens.dart';
import 'icon3d_registry.dart';
import 'interactive.dart' show Tilt3D;

/// A soft-3D rendered icon looked up by id in [Icon3DRegistry].
///
/// - [active]: pops to [Motion.activeScale] with a spring bounce and a small 3D
///   lift (nav tab, selected tile). Ids with idle art swap to it when inactive.
/// - Press: springs down to [Motion.pressScale] while a pointer is held.
/// - [tilt]: perspective tilt that follows hover/drag (default: on when tappable).
/// - [enabled] false: greyscale at 60% opacity.
/// - Reduced motion (MediaQuery.disableAnimations): no tilt, bounce or lift; the
///   final state renders at once and active is shown by the art only.
/// - Missing art: a clay plate with the registry's Material glyph, same size.
class Icon3D extends StatefulWidget {
  const Icon3D(
    this.id, {
    super.key,
    this.active = false,
    this.size = 48,
    this.semanticLabel,
    this.enabled = true,
    this.onTap,
    this.tilt,
  });

  final String id;
  final bool active;

  /// Edge of the square icon in dp. A tappable icon still gets a 48dp target.
  final double size;

  /// Read by screen readers. Null = decorative (excluded from semantics).
  final String? semanticLabel;
  final bool enabled;
  final VoidCallback? onTap;
  final bool? tilt;

  @override
  State<Icon3D> createState() => _Icon3DState();
}

class _Icon3DState extends State<Icon3D> with SingleTickerProviderStateMixin {
  /// Current scale. Unbounded so the spring can overshoot (the bounce).
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _pressed = false;
  bool _started = false;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  double get _target => _pressed
      ? Motion.pressScale
      : widget.active
      ? Motion.activeScale
      : 1;

  void _settle() {
    if (_still) {
      _scale.value = 1;
      return;
    }
    if (_scale.value == _target && !_scale.isAnimating) return;
    _scale.animateWith(
      SpringSimulation(
        Motion.iconBounce,
        _scale.value,
        _target,
        _scale.velocity,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First build pops an already-active icon in; later a reduced-motion switch snaps flat.
    if (!_started || _still) _settle();
    _started = true;
  }

  @override
  void didUpdateWidget(Icon3D old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _settle();
  }

  void _press(bool down) {
    if (!widget.enabled || _pressed == down) return;
    _pressed = down;
    _settle();
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    Widget icon = _Icon3DArt(
      id: widget.id,
      size: size,
      idle: !widget.active,
      enabled: widget.enabled,
    );
    if (!_still) {
      icon = AnimatedBuilder(
        animation: _scale,
        child: icon,
        builder: (_, child) {
          final s = _scale.value;
          // At rest: no transform layer (keeps hit-testing and goldens plain).
          if (s == 1 && !_scale.isAnimating) return child!;
          final lift = ((s - 1) / (Motion.activeScale - 1)).clamp(-1.0, 1.5);
          // Tip back while the spring moves, flat once settled: the 3D "pop".
          final wobble = (_scale.velocity * 0.055).clamp(
            -Motion.iconTiltMax,
            Motion.iconTiltMax,
          );
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..translateByDouble(0, -size * 0.06 * lift, 0, 1)
            ..rotateX(wobble)
            ..scaleByDouble(s, s, 1, 1);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: child,
          );
        },
      );
      if (widget.tilt ?? widget.onTap != null) {
        icon = Tilt3D(
          maxAngle: Motion.iconTiltMax,
          radius: BorderRadius.circular(Radii.icon3dPlate(size)),
          child: icon,
        );
      }
      icon = Listener(
        onPointerDown: (_) => _press(true),
        onPointerUp: (_) => _press(false),
        onPointerCancel: (_) => _press(false),
        child: icon,
      );
    }
    final label = widget.semanticLabel;
    if (widget.onTap != null) {
      icon = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(widthFactor: 1, heightFactor: 1, child: icon),
        ),
      );
    }
    if (label == null) return ExcludeSemantics(child: icon);
    return Semantics(
      label: label,
      button: widget.onTap != null,
      image: widget.onTap == null,
      enabled: widget.onTap == null ? null : widget.enabled,
      selected: widget.active ? true : null,
      excludeSemantics: true,
      child: icon,
    );
  }
}

/// The art (or its fallback plate), without motion.
class _Icon3DArt extends StatelessWidget {
  const _Icon3DArt({
    required this.id,
    required this.size,
    required this.idle,
    required this.enabled,
  });
  final String id;
  final double size;
  final bool idle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final spec = Icon3DRegistry.of(id);
    final dimIdle = idle && spec.hasIdle;
    Widget art = Image.asset(
      Icon3DRegistry.assetFor(id, idle: idle),
      package: Icon3DRegistry.package,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // Keeps the old frame while the idle/active file swaps: no blink.
      gaplessPlayback: true,
      excludeFromSemantics: true,
      frameBuilder: (_, child, frame, sync) =>
          frame == null && !sync ? SizedBox.square(dimension: size) : child,
      errorBuilder: (_, _, _) => Clay3DPlate(
        icon: spec.icon,
        hue: dimIdle ? const Color(0xFF8C9AA3) : spec.hue,
        size: size,
      ),
    );
    if (!enabled) {
      art = Opacity(
        opacity: 0.6,
        child: ColorFiltered(colorFilter: _greyscale, child: art),
      );
    }
    return SizedBox.square(
      key: ValueKey('icon3d:$id'),
      dimension: size,
      child: art,
    );
  }
}

const _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Claymorphic plate: vertical gradient in [hue], inner top highlight, hairline
/// rim, soft coloured contact shadow and an embossed glyph. The fallback for
/// [Icon3D] while art is missing; sizes 24-160 keep the same proportions.
class Clay3DPlate extends StatelessWidget {
  const Clay3DPlate({
    super.key,
    required this.icon,
    required this.hue,
    this.size = 56,
  });
  final IconData icon;
  final Color hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = BorderRadius.circular(Radii.icon3dPlate(size));
    final base = c.isDark ? Color.lerp(hue, Colors.black, 0.28)! : hue;
    final top = Color.lerp(base, Colors.white, c.isDark ? 0.16 : 0.30)!;
    // Light plates (check yellow) carry an ink glyph; everything else white.
    final glyph = base.computeLuminance() > 0.45
        ? const Color(0xFF17232C)
        : Colors.white;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        // Outer decoration carries the shadow; clipping happens on the inner layer.
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: Elevation.icon3d(
            base.withValues(alpha: c.isDark ? 1 : 0.9),
            size,
          ),
        ),
        child: ClipRRect(
          borderRadius: r,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, base],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: c.isDark ? 0.14 : 0.35),
              ),
              borderRadius: r,
            ),
            child: Stack(
              children: [
                // Inner top highlight: the lit upper lip of a clay tile.
                Positioned(
                  left: size * 0.10,
                  right: size * 0.10,
                  top: size * 0.05,
                  height: size * 0.38,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.22),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.38),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    icon,
                    size: size * 0.5,
                    color: glyph,
                    // Emboss: a light lip above and a soft shadow below the glyph.
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.45),
                        offset: Offset(0, -size * 0.015),
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        offset: Offset(0, size * 0.03),
                        blurRadius: size * 0.05,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
