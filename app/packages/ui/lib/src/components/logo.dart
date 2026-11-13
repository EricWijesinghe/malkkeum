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

//// The Dahae mark: a house with a checkmark inside ("we do all your chores"),
/// optionally followed by the wordmark ([BrandConfig.name]) and a [tagline].
///
/// Wordmark colour: [BrandConfig.primary] on light surfaces, white on dark,
/// teal or ink ones ([onDark]; defaults to the theme brightness).
/// [animate]: the mark plays once on first build: the 24 `logo_3d_fNN` frames
/// for [DahaeLogoVariant.threeD], or the check stroke drawing in for the
/// vector variants (also the fallback while frames are missing). Reduced
/// motion shows the final frame at once.
class DahaeLogo extends StatefulWidget {
  const DahaeLogo({
    super.key,
    this.variant = DahaeLogoVariant.flat,
    this.size = 48,
    this.color,
    this.wordmark = false,
    this.brand = BrandConfig.placeholder,
    this.semanticLabel,
    this.onDark,
    this.tagline,
    this.animate = false,
  });

  final DahaeLogoVariant variant;
  final double size;

  /// Mono colour (defaults to the theme ink). Ignored by flat and 3D.
  final Color? color;
  final bool wordmark;
  final BrandConfig brand;

  /// Defaults to the brand name; the mark is one image to screen readers.
  final String? semanticLabel;

  /// Lockup sits on a dark, teal or ink surface: white wordmark. Null = theme.
  final bool? onDark;

  /// Line under the wordmark ("집안일, 다 해드려요"); pass the localized text.
  /// Shown only with [wordmark].
  final String? tagline;
  final bool animate;

  /// Frame files (one 288px density) in `packages/ui/assets/icons3d/`.
  static const frameCount = 24;
  static String frameAsset(int i) =>
      'assets/icons3d/logo_3d_f${i.toString().padLeft(2, '0')}.webp';

  @override
  State<DahaeLogo> createState() => _DahaeLogoState();
}

class _DahaeLogoState extends State<DahaeLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _play;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || _started) return;
    _started = true;
    final c = _play = AnimationController(
      vsync: this,
      duration: Motion.logoPlay,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      c.value = 1;
      return;
    }
    if (widget.variant == DahaeLogoVariant.threeD) {
      // Decode every frame up front so the sequence never shows a gap.
      for (var i = 0; i < DahaeLogo.frameCount; i++) {
        precacheImage(
          AssetImage(DahaeLogo.frameAsset(i), package: Icon3DRegistry.package),
          context,
          onError: (_, _) {},
        );
      }
    }
    c.forward();
  }

  @override
  void dispose() {
    _play?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final size = w.size;
    final play = _play;
    final mark = SizedBox.square(
      dimension: size,
      child: play == null
          ? _mark(context, 1)
          : RepaintBoundary(
              child: AnimatedBuilder(
                animation: play,
                builder: (context, _) => _mark(context, play.value),
              ),
            ),
    );
    final onDark = w.onDark ?? context.colors.isDark;
    final tagline = w.tagline;
    final words = Text(
      w.brand.name,
      style: TextStyle(
        fontFamily: 'Pretendard',
        package: 'ui',
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        fontSize: size * 0.62,
        height: 1,
        color: w.variant == DahaeLogoVariant.mono
            ? (w.color ?? context.colors.ink)
            : onDark
            ? Colors.white
            : w.brand.primary,
      ),
    );
    final body = w.wordmark
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              SizedBox(width: size * 0.22),
              if (tagline == null)
                words
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    words,
                    SizedBox(height: size * 0.1),
                    Text(
                      tagline,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        package: 'ui',
                        fontWeight: FontWeight.w500,
                        fontSize: size * 0.2,
                        height: 1.2,
                        color: onDark ? Neutral.c300 : Neutral.c500,
                      ),
                    ),
                  ],
                ),
            ],
          )
        : mark;
    return Semantics(
      label: w.semanticLabel ?? w.brand.name,
      image: true,
      excludeSemantics: true,
      child: body,
    );
  }

  /// The mark at play position [t] (1 = at rest).
  Widget _mark(BuildContext context, double t) {
    final w = widget;
    final checkT = Curves.easeOutCubic.transform(
      const Interval(0.35, 1).transform(t),
    );
    final flat = CustomPaint(
      painter: DahaeMarkPainter(w.brand, checkT: checkT),
    );
    return switch (w.variant) {
      DahaeLogoVariant.flat => flat,
      DahaeLogoVariant.mono => CustomPaint(
        painter: DahaeMarkPainter(
          w.brand,
          mono: w.color ?? context.colors.ink,
          checkT: checkT,
        ),
      ),
      DahaeLogoVariant.threeD => Image.asset(
        // Once played, the last frame stays (the static art is a different pose).
        _play == null
            ? Icon3DRegistry.assetFor('logo_3d', size: w.size)
            : DahaeLogo.frameAsset((t * (DahaeLogo.frameCount - 1)).round()),
        package: Icon3DRegistry.package,
        width: w.size,
        height: w.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => flat,
      ),
    };
  }
}

// Paints the mark into its square. Geometry traced from the master art
/// (design/dahae-3d appicon/logo_flat_1024.png) in a 1024 grid.
class DahaeMarkPainter extends CustomPainter {
  const DahaeMarkPainter(this.brand, {this.mono, this.checkT = 1});
  final BrandConfig brand;

  /// How much of the check is drawn, 0..1 (the logo animation).
  final double checkT;

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
    final fullCheck = Path()
      ..moveTo(345 * k, 650 * k)
      ..lineTo(455 * k, 760 * k)
      ..lineTo(690 * k, 520 * k);
    final check = checkT >= 1 ? fullCheck : _partial(fullCheck, checkT);
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
      old.brand != brand || old.mono != mono || old.checkT != checkT;

  static Path _partial(Path path, double t) {
    final out = Path();
    if (t <= 0) return out;
    final metric = path.computeMetrics().first;
    return out..addPath(metric.extractPath(0, metric.length * t), Offset.zero);
  }
}
