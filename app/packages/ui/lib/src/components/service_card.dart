import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'glyph.dart';
import 'interactive.dart';

/// Service card with depth: a hue-tinted face with a colored lift shadow, the
/// clay [ServiceGlyph] floating above the face, and a tilt that follows touch
/// or hover (Tilt3D). Reduced motion keeps the layout and drops the tilt.
class ServiceCard3D extends StatelessWidget {
  const ServiceCard3D({
    super.key,
    required this.code,
    required this.title,
    this.onTap,
    this.heroTag,
    this.glyphSize = 64,
  });

  final String code;
  final String title;
  final VoidCallback? onTap;

  /// Pass the same tag as the detail screen's glyph to get a shared-element flight.
  final Object? heroTag;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hue = ServiceHues.of(code);
    final r = BorderRadius.circular(Radii.card);
    final face = c.tintOf(hue);
    final glyph = ServiceGlyph(code, size: glyphSize);
    return RepaintBoundary(
      child: Tilt3D(
        radius: r,
        child: Pressable(
          radius: r,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(face, Colors.white, c.isDark ? 0.06 : 0.5)!,
                  face,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: c.isDark ? 0.10 : 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: hue.tone.withValues(alpha: c.isDark ? 0.30 : 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The glyph floats above the face: lifted and shadowed by its own clay depth.
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: heroTag == null
                      ? glyph
                      : Hero(tag: heroTag!, child: glyph),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  title,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
