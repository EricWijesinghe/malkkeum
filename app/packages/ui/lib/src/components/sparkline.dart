import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../theme.dart';

/// Earnings sparkline: a line with a gradient fill that sweeps in left to right
/// on first build. Values are plain won amounts; the scale is min..max of the
/// series. Fewer than two points draws nothing. Reduced motion draws at rest.
class EarningsSparkline extends StatefulWidget {
  const EarningsSparkline({
    super.key,
    required this.values,
    this.height = 72,
    this.color,
    this.semanticLabel,
  });

  final List<int> values;
  final double height;
  final Color? color;
  final String? semanticLabel;

  @override
  State<EarningsSparkline> createState() => _EarningsSparklineState();
}

class _EarningsSparklineState extends State<EarningsSparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
    final color = widget.color ?? context.colors.fresh;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: EarningsSparklinePainter(
                values: widget.values,
                progress: Curves.easeOutCubic.transform(_c.value),
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the series; public so tests can assert on what is drawn.
class EarningsSparklinePainter extends CustomPainter {
  EarningsSparklinePainter({
    required this.values,
    required this.progress,
    required this.color,
  });

  final List<int> values;

  /// 0..1 sweep across the width.
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || progress <= 0) return;
    final lo = values.reduce((a, b) => a < b ? a : b).toDouble();
    final hi = values.reduce((a, b) => a > b ? a : b).toDouble();
    final span = hi - lo <= 0 ? 1.0 : hi - lo;
    final pad = size.height * 0.08;
    final h = size.height - pad * 2;
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          pad + h - (values[i] - lo) / span * h,
        ),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
    if (progress >= 1) {
      canvas.drawCircle(points.last, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(EarningsSparklinePainter old) =>
      old.progress != progress ||
      old.color != color ||
      !listEquals(old.values, values);
}
