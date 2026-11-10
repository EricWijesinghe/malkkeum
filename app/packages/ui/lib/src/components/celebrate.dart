import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens.dart';

/// Success moment: ring fills, check draws, small confetti burst in service colors.
class SuccessMark extends StatefulWidget {
  const SuccessMark({super.key, this.size = 112, this.semanticLabel});
  final double size;
  final String? semanticLabel;

  @override
  State<SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<SuccessMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.semanticLabel,
        child: SizedBox.square(
          dimension: widget.size * 1.8,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _MarkPainter(_c.value, context.colors.fresh, widget.size)),
          ),
        ),
      );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t, this.color, this.size);
  final double t;
  final Color color;
  final double size;

  static const _confetti = [
    Color(0xFF3B5BFD), Color(0xFFFFB400), Color(0xFFC72D6C), Color(0xFF0B8AA3), Color(0xFF5E3FD6), Color(0xFF3E8A12),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final center = s.center(Offset.zero);
    final r = size / 2;
    final ring = Curves.easeOutCubic.transform((t / 0.45).clamp(0, 1));
    canvas.drawCircle(center, r * ring, Paint()..color = color);

    final checkT = Curves.easeOutCubic.transform(((t - 0.35) / 0.4).clamp(0, 1));
    if (checkT > 0) {
      final p1 = center + Offset(-r * 0.38, r * 0.02);
      final p2 = center + Offset(-r * 0.1, r * 0.3);
      final p3 = center + Offset(r * 0.42, -r * 0.28);
      final path = Path()..moveTo(p1.dx, p1.dy);
      final first = (checkT * 2).clamp(0.0, 1.0);
      path.lineTo(p1.dx + (p2.dx - p1.dx) * first, p1.dy + (p2.dy - p1.dy) * first);
      if (checkT > 0.5) {
        final second = (checkT - 0.5) * 2;
        path.lineTo(p2.dx + (p3.dx - p2.dx) * second, p2.dy + (p3.dy - p2.dy) * second);
      }
      canvas.drawPath(path, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }

    final burst = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    if (burst > 0 && burst < 1) {
      for (var i = 0; i < 18; i++) {
        final angle = i / 18 * 2 * math.pi + i * 0.3;
        final dist = r * (1.15 + 0.6 * Curves.easeOut.transform(burst));
        final pos = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
        final paint = Paint()..color = _confetti[i % _confetti.length].withValues(alpha: 1 - burst);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: 8, height: 5), const Radius.circular(2)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}

/// Animated number for prices so changes read as change, not flicker.
class RollingAmount extends StatelessWidget {
  const RollingAmount({super.key, required this.value, required this.format, this.style});
  final int value;
  final String Function(int) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.toDouble()),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Motion.standard,
        curve: Motion.ease,
        builder: (_, v, _) => Text(format(v.round()), style: style),
      );
}
