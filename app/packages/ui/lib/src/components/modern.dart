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

//// Pill segmented control. Each segment is at least 48dp tall; the white
/// thumb slides to the selected segment (transform only, instant under
/// reduced motion).
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
    final index = segments.indexWhere((s) => s.$1 == selected);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: 1 / segments.length,
                  heightFactor: 1,
                  child: AnimatedSlide(
                    offset: Offset(
                      rtl ? -index.toDouble() : index.toDouble(),
                      0,
                    ),
                    duration: motionFor(context, Motion.route),
                    curve: Motion.emphasized,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(Radii.pill),
                        boxShadow: Elevation.card,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Row(
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
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: AnimatedDefaultTextStyle(
              duration: motionFor(context, Motion.standard),
              curve: Motion.ease,
              style: context.text.labelLarge!.copyWith(
                color: selected ? c.ink : c.inkMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress track whose fill grows to [fraction] (0..1) on first build and
/// glides on every change ([Motion.progress], emphasized). Paint-only: the fill
/// scales, nothing relayouts. Horizontal fills from the start edge, vertical
/// from the top. Reduced motion shows the value at once.
class ProgressLine extends StatelessWidget {
  const ProgressLine({
    super.key,
    required this.fraction,
    this.color,
    this.trackColor,
    this.thickness = 4,
    this.axis = Axis.horizontal,
  });

  final double fraction;

  /// Fill; defaults to the theme's fresh teal.
  final Color? color;

  /// Track behind the fill; defaults to the theme line colour.
  final Color? trackColor;
  final double thickness;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final horizontal = axis == Axis.horizontal;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(thickness / 2);
    final f = fraction.clamp(0.0, 1.0);
    return SizedBox(
      width: horizontal ? double.infinity : thickness,
      height: horizontal ? thickness : double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: trackColor ?? c.line,
          borderRadius: radius,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: f),
          duration: motionFor(context, Motion.progress),
          curve: Motion.emphasized,
          builder: (_, v, child) => Transform(
            alignment: horizontal
                ? (rtl ? Alignment.centerRight : Alignment.centerLeft)
                : Alignment.topCenter,
            transform: Matrix4.diagonal3Values(
              horizontal ? v : 1,
              horizontal ? 1 : v,
              1,
            ),
            child: child,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? c.fresh,
              borderRadius: radius,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

// Read-only star rating; half stars for .5 values. [label] is the spoken value.
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
