import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import '../tokens.dart';
import 'depth.dart';
import 'glyph.dart';
import 'icon3d.dart';
import 'interactive.dart';

/// "52,000원" in Korean, "₩52,000" elsewhere.
String formatWon(int amount, String locale) {
  final n = NumberFormat.decimalPattern(locale).format(amount);
  return locale.startsWith('ko') ? '$n원' : '₩$n';
}

/// Unit shown next to a won input field.
String currencyUnit(String locale) => locale.startsWith('ko') ? '원' : '₩';

/// Controllers owned by a dialog/sheet must outlive its closing animation;
/// disposing right after `await showDialog` can hit a still-mounted TextField.
void disposeAfterClose(Iterable<ChangeNotifier> controllers) {
  Future<void>.delayed(const Duration(milliseconds: 600), () {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

IconData serviceIcon(String code) => switch (code) {
  'studio' => Icons.door_front_door_rounded,
  'kitchen' => Icons.soup_kitchen_rounded,
  'bathroom' => Icons.bathtub_rounded,
  'mattress' => Icons.king_bed_rounded,
  'aircon' => Icons.ac_unit_rounded,
  'sofa' => Icons.weekend_rounded,
  'move_out' => Icons.local_shipping_rounded,
  'move_in' => Icons.vpn_key_rounded,
  _ => Icons.cleaning_services_rounded,
};

extension ResponsiveX on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  bool get isWide => width >= Breakpoints.medium;
  bool get isCompact => width < Breakpoints.compact;
}

/// Card on the surface scale. Tappable cards get [Pressable] (spring + haptic).
/// Dark mode lifts with a hairline border and a brand halo, not a black shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.color,
    this.border,
    this.level = Level.card,
    this.glow,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? border;
  final Level level;

  /// Tints the dark-mode halo (e.g. a service hue). Defaults to the brand accent.
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(Radii.card);
    final edge = border ?? (c.isDark ? c.line : null);
    return Pressable(
      enabled: onTap != null,
      onTap: onTap,
      radius: radius,
      shadows: Depth.of(c, level, glow: glow),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? c.surface,
          borderRadius: radius,
          border: edge == null
              ? null
              : Border.all(color: edge, width: border == null ? 1 : 1.5),
        ),
        // Own Material so ListTile ink/background isn't hidden by the colored decoration.
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.label});
  final int status;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Tag(label: label, hue: StatusHues.of(status));
}

class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, required this.hue, this.icon});
  final String label;
  final ServiceHue hue;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = context.colors.isDark ? hue.tint : hue.tone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.tintOf(hue),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          // Flexible: a long translation wraps inside its pill instead of overflowing the row.
          Flexible(
            child: Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: fg,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.sm),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.titleMedium),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Ink label on light fills (check yellow: 11.67:1), white on dark ones.
Color _labelOn(Color fill) =>
    fill.computeLuminance() > 0.4 ? Neutral.c900 : Colors.white;

/// Primary CTA with built-in busy state so double taps can't double charge.
/// Presses spring down and the brand glow tightens.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.color,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final c = context.colors;
    final fill = color ?? context.primary;
    // Brand gradient unless the caller passes a solid color (e.g. danger).
    final gradient = color == null && enabled
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.brandStart, c.brandEnd],
          )
        : null;
    return Pressable(
      enabled: enabled,
      radius: BorderRadius.circular(Radii.input),
      shadows: enabled
          ? [
              BoxShadow(
                color: (gradient?.colors.first ?? fill).withValues(
                  alpha: c.isDark ? 0.5 : 0.30,
                ),
                blurRadius: 18,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(Radii.input),
        ),
        child: FilledButton(
          style: gradient != null
              ? FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                )
              : color == null
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: _labelOn(color!),
                ),
          // Haptic on tap; busy/disabled never fire.
          onPressed: busy || onPressed == null ? null : _tap,
          child: AnimatedSwitcher(
            duration: Motion.micro,
            child: busy
                ? SizedBox(
                    key: const ValueKey('busy'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: color == null ? Colors.white : _labelOn(color!),
                    ),
                  )
                : Text(label, key: const ValueKey('label')),
          ),
        ),
      ),
    );
  }

  void _tap() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}

/// Sticky bottom area on a glass surface: optional summary line above the CTA.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child, this.summary});
  final Widget child;
  final Widget? summary;

  @override
  Widget build(BuildContext context) => GlassBar(
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.sm,
          Space.gutter,
          Space.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (summary != null) ...[
              summary!,
              const SizedBox(height: Space.sm),
            ],
            child,
          ],
        ),
      ),
    ),
  );
}

/// Segmented progress for multi-step flows.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.current,
    required this.total,
    this.color,
  });
  final int current;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$current / $total',
    child: Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.standard,
              curve: Motion.ease,
              height: 4,
              decoration: BoxDecoration(
                color: i < current
                    ? (color ?? context.primary)
                    : context.colors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.hue,
    this.codes = const ['studio', 'kitchen', 'bathroom'],
    this.art,
  });
  final IconData icon;

  /// An Icon3D id shown instead of the glyph cluster (e.g. 'p_verified'); [icon] is then unused.
  final String? art;
  final String title;
  final String? body;
  final Widget? action;
  final ServiceHue? hue;

  /// Three service codes for the cluster (left, right, front).
  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final h = hue ?? ServiceHues.bathroom;
    // Scrolls rather than overflows when a short screen meets a large system font.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (art case final id?)
              ExcludeSemantics(child: Icon3D(id, size: 112))
            else
              _GlyphCluster(codes: codes, icon: icon, hue: h),
            const SizedBox(height: Space.lg),
            Text(
              title,
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                body!,
                style: context.text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: Space.xl), action!],
          ],
        ),
      ),
    );
  }
}

/// Empty state drawn from clay service glyphs (a composition, not a plain icon).
class _GlyphCluster extends StatelessWidget {
  const _GlyphCluster({
    required this.codes,
    required this.icon,
    required this.hue,
  });
  final List<String> codes;
  final IconData icon;
  final ServiceHue hue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 176,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 26,
            child: Transform.rotate(
              angle: -0.14,
              child: ServiceGlyph(codes[0], size: 64),
            ),
          ),
          Positioned(
            right: 0,
            top: 26,
            child: Transform.rotate(
              angle: 0.14,
              child: ServiceGlyph(codes[1], size: 64),
            ),
          ),
          Positioned(left: 50, top: 0, child: ServiceGlyph(codes[2], size: 76)),
          Positioned(
            right: 4,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
                border: Border.all(color: c.line),
                boxShadow: Depth.of(c, Level.raised, glow: hue.tone),
              ),
              child: Icon(
                icon,
                size: 18,
                color: c.isDark ? hue.tint : hue.tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one error / offline state for every app: localized copy (never a raw exception) and a
/// retry that shows it is working. Full size fills a screen or pane; [compact] is an inline card
/// for one failed section, or a "showing older data" banner above content that stays on screen.
class ErrorRetry extends StatefulWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.compact = false,
    this.secondary,
  });
  final String message;
  final String retryLabel;

  /// When this returns a Future, the button shows progress and ignores taps until it settles.
  final FutureOr<void> Function() onRetry;
  final bool compact;

  /// A quieter action under retry (e.g. sign out). Full size only.
  final Widget? secondary;

  @override
  State<ErrorRetry> createState() => _ErrorRetryState();
}

class _ErrorRetryState extends State<ErrorRetry> {
  static const _spinner = 18.0;
  static const _rise = 12.0;
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _hue = StatusHues.cancelled;

  /// The label stays while retrying (screen readers, stable width); only the icon turns into progress.
  Widget get _retryIcon => _busy
      ? const SizedBox.square(
          dimension: _spinner,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.refresh_rounded, size: _spinner);

  Widget _card(BuildContext context) {
    final c = context.colors;
    return AppCard(
      level: Level.flat,
      border: c.line,
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.xs,
        Space.xs,
        Space.xs,
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.wifi_off_rounded,
              size: 20,
              color: c.isDark ? _hue.tint : _hue.tone,
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(widget.message, style: context.text.bodyMedium)),
          TextButton.icon(
            onPressed: _busy ? null : _retry,
            icon: _retryIcon,
            label: Text(widget.retryLabel),
          ),
        ],
      ),
    );
  }

  Widget _page() => EmptyState(
    icon: Icons.wifi_off_rounded,
    title: widget.message,
    hue: _hue,
    action: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _retry,
          icon: _retryIcon,
          label: Text(widget.retryLabel),
        ),
        if (widget.secondary case final more?) ...[
          const SizedBox(height: Space.xs),
          more,
        ],
      ],
    ),
  );

  // Announced when it appears; fades and rises in once (at once under reduced motion).
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Motion.route,
      curve: Motion.emphasized,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, _rise * (1 - v)),
          child: child,
        ),
      ),
      child: widget.compact ? _card(context) : _page(),
    ),
  );
}

/// Calm placeholder block while data loads (no spinners on content).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 72, this.radius = Radii.card});
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  // One sweeping highlight band per loop; the band is static under reduced motion.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final box = BoxDecoration(
      color: c.line,
      borderRadius: BorderRadius.circular(widget.radius),
    );
    return RepaintBoundary(
      child: Container(
        height: widget.height,
        decoration: box,
        child: reduce
            ? null
            : AnimatedBuilder(
                animation: _c,
                builder: (_, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    gradient: LinearGradient(
                      begin: Alignment(-3 + 4 * _c.value, 0),
                      end: Alignment(1 + 4 * _c.value, 0),
                      colors: [c.line, c.surfaceHigh, c.line],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Loading placeholder for a list: [count] shimmering rows in place of a spinner.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.rowHeight = 72});
  final int count;
  final double rowHeight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Space.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Skeleton(height: rowHeight),
          ),
      ],
    ),
  );
}

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.md,
          ),
          child: Text(title, style: ctx.text.titleLarge),
        ),
        Flexible(child: builder(ctx)),
      ],
    ),
  ),
);

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
