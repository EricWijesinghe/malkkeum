import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'basics.dart' show serviceIcon;

/// Claymorphic service tile: vertical gradient in the service hue, inner top
/// highlight, hairline rim, soft colored drop shadow below, and an embossed
/// icon. Sizes 36-120 keep the same proportions.
class ServiceGlyph extends StatelessWidget {
  const ServiceGlyph(this.code, {super.key, this.size = 56});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hue = ServiceHues.of(code);
    final r = BorderRadius.circular(size * 0.32);
    final base = c.isDark
        ? Color.lerp(hue.tone, Colors.black, 0.28)!
        : hue.tone;
    final top = Color.lerp(base, Colors.white, c.isDark ? 0.16 : 0.30)!;
    final shadowAlpha = c.isDark ? 0.45 : 0.32;
    return Semantics(
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          // Outer decoration carries the shadow; clipping happens on the inner layer.
          decoration: BoxDecoration(
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: shadowAlpha),
                blurRadius: size * 0.30,
                offset: Offset(0, size * 0.14),
                spreadRadius: -size * 0.04,
              ),
            ],
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
                  width: 1,
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
                      serviceIcon(code),
                      size: size * 0.5,
                      color: Colors.white,
                      // Emboss: a light lip above and a soft shadow below the glyph.
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.45),
                          offset: Offset(0, -size * 0.015),
                          blurRadius: 0,
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
      ),
    );
  }
}
