import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';
import '../tokens.dart';
import 'basics.dart' show formatWon;

/// OS "reduce motion" (Remove animations). Every motion helper below checks it.
bool reducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

Duration motionFor(BuildContext context, Duration d) =>
    reducedMotion(context) ? Duration.zero : d;

/// Brand fill for hero surfaces: primary to deep primary, top-left to bottom-right.
LinearGradient brandGradient(BrandConfig brand) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [brand.primary, brand.primaryDeep],
);

/// Fade + rise on entry. [delay] staggers siblings. Reduced motion shows the child at once.
class EnterMotion extends StatelessWidget {
  const EnterMotion({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: Motion.standard, curve: Motion.ease)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: Motion.route,
          curve: Motion.emphasized,
        );
  }
}

/// Pill segmented control. Each segment is at least 48dp tall.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        children: [
          for (final (value, label) in segments)
            Expanded(
              child: _Segment(
                label: label,
                selected: value == selected,
                onTap: () => onChanged(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.pill),
          onTap: onTap,
          child: AnimatedContainer(
            duration: motionFor(context, Motion.standard),
            curve: Motion.ease,
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            decoration: BoxDecoration(
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.pill),
              boxShadow: selected ? Elevation.card : const [],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge?.copyWith(
                color: selected ? c.ink : c.inkMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only star rating; half stars for .5 values. [label] is the spoken value.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.label,
    this.size = 18,
    this.count = 5,
  });

  final double rating;
  final String? label;
  final double size;
  final int count;

  @override
  Widget build(BuildContext context) {
    final fill = context.colors.sun;
    final empty = context.colors.line;
    return Semantics(
      label: label ?? '${rating.toStringAsFixed(1)} / $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Icon(
                rating - i >= 1
                    ? Icons.star_rounded
                    : rating - i >= 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_rounded,
                size: size,
                color: rating - i >= 0.5 ? fill : empty,
              ),
          ],
        ),
      ),
    );
  }
}

/// Avatar with a status ring: mint ring when [online], hairline otherwise.
class AvatarRing extends StatelessWidget {
  const AvatarRing({
    super.key,
    required this.child,
    this.online = false,
    this.size = 48,
  });

  final Widget child;
  final bool online;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: online ? c.fresh : c.line,
          width: online ? 2.5 : 1,
        ),
      ),
      child: ClipOval(child: child),
    );
  }
}

/// Won amount in a sun-tinted pill. Value changes count to the new amount.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.amount, required this.locale});

  final int amount;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.sunTint,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        child: CountUp(
          value: amount,
          format: (v) => formatWon(v, locale),
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Number that tweens from its previous value. Reduced motion jumps straight to the value.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = Motion.route,
  });

  final int value;
  final String Function(int) format;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: motionFor(context, duration),
      curve: Motion.ease,
      builder: (_, v, _) => Text(format(v.round()), style: style),
    );
  }
}

/// One soft up-and-down scale on [child] when it becomes [active] (e.g. the current step).
/// It settles after one beat, so pumpAndSettle never waits on it. Reduced motion keeps the child still.
class Pulse extends StatelessWidget {
  const Pulse({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active || reducedMotion(context)) return child;
    return child
        .animate()
        .scaleXY(
          begin: 1,
          end: 1.12,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(
          begin: 1.12,
          end: 1,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
  }
}
