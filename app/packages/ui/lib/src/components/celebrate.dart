import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens.dart';

/// Success moment: the 3D `confirm_check` (teal disc, yellow check, sparkle)
/// pops in as a 24-frame sequence behind one expanding halo ring, with one
/// medium haptic. Without the art, the painter draws the ring, the check and a
/// confetti burst instead. Reduced motion shows the final frame at once.
class SuccessMark extends StatefulWidget {
  const SuccessMark({super.key, this.size = 112, this.semanticLabel});
  final double size;
  final String? semanticLabel;

  /// Frame files (one 288px density) in `packages/ui/assets/icons3d/`.
  static const frameCount = 24;
  static String frameAsset(int i) =>
      'assets/icons3d/confirm_check_f${i.toString().padLeft(2, '0')}.webp';

  @override
  State<SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<SuccessMark>
    with SingleTickerProviderStateMixin {
  // 24 frames at 30 fps; the painter fallback uses the same clock.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool _cached = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cached) return;
    _cached = true;
    // Decode every frame up front so the sequence never shows a gap.
    for (var i = 0; i < SuccessMark.frameCount; i++) {
      precacheImage(
        AssetImage(SuccessMark.frameAsset(i), package: 'ui'),
        context,
        onError: (_, _) {},
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    image: widget.semanticLabel != null,
    child: SizedBox.square(
      dimension: widget.size * 1.8,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final frame = (_c.value * (SuccessMark.frameCount - 1)).round();
          return CustomPaint(
            // One ring, 600 ms of the 800 ms clock, starting as the disc lands.
            painter: _HaloPainter(
              const Interval(0.2, 0.95).transform(_c.value),
              context.colors.fresh,
              widget.size,
            ),
            child: Center(
              child: Image.asset(
                SuccessMark.frameAsset(frame),
                package: 'ui',
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                gaplessPlayback: true,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => CustomPaint(
                  size: Size.square(widget.size * 1.8),
                  painter: _MarkPainter(
                    _c.value,
                    context.colors.fresh,
                    widget.size,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Expanding ring (fresh at 25% fading out) behind the success mark.
class _HaloPainter extends CustomPainter {
  _HaloPainter(this.t, this.color, this.size);
  final double t;
  final Color color;
  final double size;

  @override
  void paint(Canvas canvas, Size s) {
    if (t <= 0 || t >= 1) return;
    final e = Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
      s.center(Offset.zero),
      size * (0.5 + 0.4 * e),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.06 * (1 - e) + 1
        ..color = color.withValues(alpha: 0.25 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.t != t || old.color != color;
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t, this.color, this.size);
  final double t;
  final Color color;
  final double size;

  static const _confetti = [
    Color(0xFF1E9EBA),
    Color(0xFFFFD95A),
    Color(0xFF187A8F),
    Color(0xFF5CC8DE),
    Color(0xFFFFE89A),
    Color(0xFF17232C),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final center = s.center(Offset.zero);
    final r = size / 2;
    final ring = Curves.easeOutCubic.transform((t / 0.45).clamp(0, 1));
    canvas.drawCircle(center, r * ring, Paint()..color = color);

    final checkT = Curves.easeOutCubic.transform(
      ((t - 0.35) / 0.4).clamp(0, 1),
    );
    if (checkT > 0) {
      final p1 = center + Offset(-r * 0.38, r * 0.02);
      final p2 = center + Offset(-r * 0.1, r * 0.3);
      final p3 = center + Offset(r * 0.42, -r * 0.28);
      final path = Path()..moveTo(p1.dx, p1.dy);
      final first = (checkT * 2).clamp(0.0, 1.0);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * first,
        p1.dy + (p2.dy - p1.dy) * first,
      );
      if (checkT > 0.5) {
        final second = (checkT - 0.5) * 2;
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * second,
          p2.dy + (p3.dy - p2.dy) * second,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFD95A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.09
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final burst = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    if (burst > 0 && burst < 1) {
      for (var i = 0; i < 18; i++) {
        final angle = i / 18 * 2 * math.pi + i * 0.3;
        final dist = r * (1.15 + 0.6 * Curves.easeOut.transform(burst));
        final pos =
            center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
        final paint = Paint()
          ..color = _confetti[i % _confetti.length].withValues(
            alpha: 1 - burst,
          );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: pos, width: 8, height: 5),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}

/// Animated number for prices so changes read as change, not flicker.
class RollingAmount extends StatelessWidget {
  const RollingAmount({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });
  final int value;
  final String Function(int) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Motion.standard,
    curve: Motion.ease,
    builder: (_, v, _) => Text(format(v.round()), style: style),
  );
}

/// Amount that changes by sliding the new value up into place while the old
/// one fades (price bars, totals, counters). Whole-text swap, so it stays
/// correct at 200% text scale. Reduced motion swaps at once.
class AmountSwitcher extends StatelessWidget {
  const AmountSwitcher({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.alignment = AlignmentDirectional.centerStart,
  });
  final int value;
  final String Function(int) format;
  final TextStyle? style;

  /// Where old and new text line up while both are on screen.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Motion.standard,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Motion.ease,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(format(value), key: ValueKey(value), style: style),
    ),
  );
}
