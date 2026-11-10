import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Slow mesh of soft colored light behind hero surfaces. Three radial blobs on
/// a Lissajous path, drawn with cheap gradients (no blur filters). Paused and
/// frozen at phase 0 under reduced motion; wrapped in a RepaintBoundary.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.colors,
    this.period = const Duration(seconds: 16),
  });

  final Widget child;

  /// Blob colors. Defaults to the brand's trust blue, mint and sun.
  final List<Color>? colors;
  final Duration period;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduce && _c.isAnimating == !reduce) return;
    _reduce = reduce;
    if (reduce) {
      _c.stop();
      _c.value = 0;
    } else {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final palette =
        widget.colors ??
        [
          const Color(0xFF3B5BFD),
          const Color(0xFF12B48F),
          const Color(0xFFFFB400),
        ];
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(
                painter: _AuroraPainter(_c.value, palette, c.isDark),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.colors, this.dark);
  final double t;
  final List<Color> colors;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final radius = size.longestSide * 0.55;
    final phase = t * 2 * math.pi;
    for (var i = 0; i < colors.length; i++) {
      final a = phase + i * 2.1;
      final center = Offset(
        size.width * (0.5 + 0.36 * math.sin(a)),
        size.height * (0.45 + 0.30 * math.cos(a * 0.7 + i)),
      );
      final base = colors[i];
      final alpha = dark ? 0.42 : 0.22;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            base.withValues(alpha: alpha),
            base.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.dark != dark;
}

/// One floating element of a [ParallaxField]. [depth] scales how far it follows
/// the pointer (0 = fixed, 1 = closest); it also bobs gently out of phase.
class ParallaxItem {
  const ParallaxItem({
    required this.alignment,
    required this.depth,
    required this.child,
    this.phase = 0,
  });
  final Alignment alignment;
  final double depth;
  final Widget child;
  final double phase;
}

/// Floating glyph orbs that drift toward / away from the pointer (hover or drag).
/// Under reduced motion they sit still.
class ParallaxField extends StatefulWidget {
  const ParallaxField({super.key, required this.items, this.range = 26});

  final List<ParallaxItem> items;

  /// Max pointer-follow distance in logical pixels for depth 1.
  final double range;

  @override
  State<ParallaxField> createState() => _ParallaxFieldState();
}

class _ParallaxFieldState extends State<ParallaxField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  final ValueNotifier<Offset> _pointer = ValueNotifier(Offset.zero);
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _bob.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduce) return;
    _reduce = reduce;
    if (reduce) {
      _bob.stop();
      _pointer.value = Offset.zero;
    } else {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _pointer.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) {
    if (_reduce || size.isEmpty) return;
    _pointer.value = Offset(
      local.dx / size.width * 2 - 1,
      local.dy / size.height * 2 - 1,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = box.biggest;
      return MouseRegion(
        onHover: (e) => _track(e.localPosition, size),
        onExit: (_) => _pointer.value = Offset.zero,
        child: Listener(
          onPointerMove: (e) => _track(e.localPosition, size),
          onPointerUp: (_) => _pointer.value = Offset.zero,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_bob, _pointer]),
              builder: (_, _) => Stack(
                children: [
                  for (final it in widget.items)
                    Align(
                      alignment: it.alignment,
                      child: Transform.translate(
                        offset: _offsetFor(it),
                        child: it.child,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Offset _offsetFor(ParallaxItem it) {
    final p = _pointer.value;
    final bob = _reduce
        ? 0.0
        : math.sin((_bob.value + it.phase) * math.pi * 2) * 6;
    return Offset(
      p.dx * it.depth * widget.range,
      p.dy * it.depth * widget.range + bob,
    );
  }
}
