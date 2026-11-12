import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'icon3d_registry.dart';

enum DahaeLogoVariant {
  /// Vector house + check in brand colours (app bars, login, small sizes).
  flat,

  /// Rendered soft-3D art (`logo_3d`) for splash and hero; flat while missing.
  threeD,

  /// One colour with the check cut out (notifications, watermarks).
  mono,
}

/// The Dahae mark: a house with a checkmark inside ("we do all your chores"),
/// optionally followed by the wordmark ([BrandConfig.name]).
class DahaeLogo extends StatelessWidget {
  const DahaeLogo({
    super.key,
    this.variant = DahaeLogoVariant.flat,
    this.size = 48,
    this.color,
    this.wordmark = false,
    this.brand = BrandConfig.placeholder,
    this.semanticLabel,
  });

  final DahaeLogoVariant variant;
  final double size;

  /// Mono colour (defaults to the theme ink). Ignored by flat and 3D.
  final Color? color;
  final bool wordmark;
  final BrandConfig brand;

  /// Defaults to the brand name; the mark is one image to screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(dimension: size, child: _mark(context));
    final body = wordmark
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              SizedBox(width: size * 0.22),
              Text(
                brand.name,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  package: 'ui',
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  fontSize: size * 0.62,
                  height: 1,
                  color: variant == DahaeLogoVariant.mono
                      ? (color ?? context.colors.ink)
                      : context.colors.ink,
                ),
              ),
            ],
          )
        : mark;
    return Semantics(
      label: semanticLabel ?? brand.name,
      image: true,
      excludeSemantics: true,
      child: body,
    );
  }

  Widget _mark(BuildContext context) => switch (variant) {
    DahaeLogoVariant.flat => CustomPaint(painter: DahaeMarkPainter(brand)),
    DahaeLogoVariant.mono => CustomPaint(
      painter: DahaeMarkPainter(brand, mono: color ?? context.colors.ink),
    ),
    DahaeLogoVariant.threeD => Image.asset(
      Icon3DRegistry.assetFor('logo_3d'),
      package: Icon3DRegistry.package,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => CustomPaint(painter: DahaeMarkPainter(brand)),
    ),
  };
}

/// Paints the mark into its square. Geometry traced from the master art
/// (design/dahae-3d appicon/logo_flat_1024.png) in a 1024 grid.
class DahaeMarkPainter extends CustomPainter {
  const DahaeMarkPainter(this.brand, {this.mono});
  final BrandConfig brand;

  /// Single colour with the check knocked out; null = full colour.
  final Color? mono;

  @override
  void paint(Canvas canvas, Size s) {
    final k = s.shortestSide / 1024;
    Offset p(double x, double y) => Offset(x * k, y * k);
    final body = Path()
      ..moveTo(150 * k, 470 * k)
      ..lineTo(512 * k, 175 * k)
      ..lineTo(874 * k, 470 * k)
      ..lineTo(874 * k, 890 * k)
      ..arcToPoint(p(834, 930), radius: Radius.circular(40 * k))
      ..lineTo(190 * k, 930 * k)
      ..arcToPoint(p(150, 890), radius: Radius.circular(40 * k))
      ..close();
    final roof = Path()
      ..moveTo(110 * k, 440 * k)
      ..lineTo(512 * k, 110 * k)
      ..lineTo(914 * k, 440 * k);
    final check = Path()
      ..moveTo(345 * k, 650 * k)
      ..lineTo(455 * k, 760 * k)
      ..lineTo(690 * k, 520 * k);
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mono = this.mono;
    if (mono != null) {
      canvas.saveLayer(Offset.zero & s, Paint());
      canvas.drawPath(body, Paint()..color = mono);
      canvas.drawPath(roof, stroke(mono, 110));
      canvas.drawPath(check, stroke(mono, 105)..blendMode = BlendMode.clear);
      canvas.restore();
      return;
    }
    canvas.drawPath(body, Paint()..color = brand.fresh);
    canvas.drawPath(roof, stroke(brand.primary, 110));
    canvas.drawPath(check, stroke(brand.sun, 105));
  }

  @override
  bool shouldRepaint(DahaeMarkPainter old) =>
      old.brand != brand || old.mono != mono;
}
