import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Elevation levels. Light mode uses soft ink shadows; dark mode never uses a
/// black drop shadow: a raised surface gets a brand-colored halo instead.
enum Level { flat, card, raised, sheet }

abstract final class Depth {
  /// Shadow stack for [level] in the current theme. Pass [glow] to tint the halo.
  static List<BoxShadow> of(AppColors c, Level level, {Color? glow}) {
    if (level == Level.flat) return const [];
    if (!c.isDark) {
      return switch (level) {
        Level.card => Elevation.card,
        Level.raised => Elevation.raised,
        _ => Elevation.sheet,
      };
    }
    final halo = glow ?? c.accent;
    return switch (level) {
      Level.card => [
        BoxShadow(
          color: halo.withValues(alpha: 0.10),
          blurRadius: 22,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ],
      Level.raised => [
        BoxShadow(
          color: halo.withValues(alpha: 0.22),
          blurRadius: 30,
          spreadRadius: -6,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: halo.withValues(alpha: 0.06),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      _ => [
        BoxShadow(
          color: halo.withValues(alpha: 0.16),
          blurRadius: 44,
          spreadRadius: -10,
          offset: const Offset(0, -6),
        ),
      ],
    };
  }
}

/// Frosted surface for the bottom bars: blur, translucent tint, hairline top
/// border. The only place a saveLayer-style effect is allowed in lists' chrome.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.blur = 22,
    this.horizontal = true,
  });

  final Widget child;
  final double blur;

  /// False for side rails: the hairline goes on the right edge instead of the top.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: c.isDark ? 0.78 : 0.90),
            border: horizontal
                ? Border(
                    top: BorderSide(
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : c.line,
                    ),
                  )
                : Border(
                    right: BorderSide(
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : c.line,
                    ),
                  ),
          ),
          child: child,
        ),
      ),
    );
  }
}
