import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';


/// Shared pieces of the booking flows (owner design p07-p22): white page, big title,
/// grey bands between sections, circle and radio choices, 3D tiles.

/// Big page title with an optional step chip ("이사 청소 · 1/7") and body line.
class FlowTitle extends StatelessWidget {
  const FlowTitle(this.title, {super.key, this.chip, this.body});
  final String title;
  final String? chip;
  final String? body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.gutter,
      Space.xs,
      Space.gutter,
      Space.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chip != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Text(
              chip!,
              style: context.text.labelMedium?.copyWith(
                color: context.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: Space.xs),
          Text(
            body!,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Padded block inside a band-separated page.
class FlowSection extends StatelessWidget {
  const FlowSection({
    super.key,
    required this.children,
    this.title,
    this.trailing,
  });
  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.gutter,
      Space.lg,
      Space.gutter,
      Space.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title!,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ...children,
      ],
    ),
  );
}

/// The light-grey band the design puts between sections.
class FlowBand extends StatelessWidget {
  const FlowBand({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: Space.xs, color: context.colors.surfaceHigh);
}

/// Round 3D choice (cleaning type, building, elevator, duplex). Selected = teal disc + bold label.
class CircleChoice extends StatelessWidget {
  const CircleChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.text,
    this.size = 72,
  });
  final String label;
  final String? icon;

  /// A number instead of art (counters 0-5).
  final String? text;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: text == null ? null : label,
      excludeSemantics: text != null,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        radius: BorderRadius.circular(size),
        pressedScale: 0.92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Motion.standard,
              curve: Motion.ease,
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? context.primary : c.surfaceHigh,
              ),
              child: text != null
                  ? Text(
                      text!,
                      style: context.text.titleLarge?.copyWith(
                        color: selected ? Colors.white : c.ink,
                      ),
                    )
                  : ExcludeSemantics(
                      child: Icon3D(icon!, active: selected, size: size * 0.6),
                    ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: selected ? c.ink : c.inkSoft,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of [CircleChoice]s that wraps on narrow screens and large fonts.
Widget circleRow(List<Widget> children, {double width = 80}) => Wrap(
  spacing: Space.xs,
  runSpacing: Space.md,
  children: [for (final c in children) SizedBox(width: width, child: c)],
);

/// Full-width radio row: label on the left, round radio on the right (design p09, p14, p15).
class RadioRow extends StatelessWidget {
  const RadioRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.subtitleTrailing,
  });
  final String title;
  final String? subtitle;
  final Widget? subtitleTrailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.bodyLarge?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text.rich(
                          TextSpan(
                            text: subtitle,
                            children: [
                              if (subtitleTrailing != null) ...[
                                const TextSpan(text: ' '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: subtitleTrailing!,
                                ),
                              ],
                            ],
                          ),
                          style: context.text.bodyMedium?.copyWith(
                            color: c.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                AnimatedContainer(
                  duration: Motion.micro,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? context.primary : null,
                    border: Border.all(
                      color: selected ? context.primary : c.line,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label on the left, value on the right; values wrap instead of overflowing.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.inkMuted,
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style:
                valueStyle ??
                context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Teal check bullet list (기본 서비스, 안심예약 benefits).
class CheckList extends StatelessWidget {
  const CheckList(this.items, {super.key, this.filled = true});
  final List<String> items;
  final bool filled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                filled ? Icons.check_circle_rounded : Icons.check_rounded,
                color: context.colors.fresh,
                size: 24,
              ),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(item, style: context.text.bodyLarge)),
            ],
          ),
        ),
    ],
  );
}

/// Grey rounded note box with "·" bullets (꼭 확인해 주세요, 제공하지 않는 서비스).
class NoteBox extends StatelessWidget {
  const NoteBox({
    super.key,
    required this.items,
    this.title,
    this.danger = const {},
  });
  final String? title;
  final List<String> items;

  /// Indexes drawn in the danger colour (the direct-deal warning).
  final Set<int> danger;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.md),
    decoration: BoxDecoration(
      color: context.colors.surfaceHigh,
      borderRadius: BorderRadius.circular(Radii.tile),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(title!, style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
        ],
        for (final (i, item) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '·  $item',
              style: context.text.bodySmall?.copyWith(
                color: danger.contains(i)
                    ? context.colors.danger
                    : context.colors.inkSoft,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Vertical choice tile: 3D icon over its label (AC unit cards). A check badge marks the choice.
class ChoiceTile3D extends StatelessWidget {
  const ChoiceTile3D({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.accent,
  });
  final String icon;
  final String label;
  final String? subtitle;

  /// Bold last line (the price).
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = accent ?? context.primary;
    final radius = BorderRadius.circular(Radii.tile);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        radius: radius,
        child: AnimatedContainer(
          duration: Motion.standard,
          curve: Motion.ease,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    a.withValues(alpha: c.isDark ? 0.18 : 0.06),
                    c.surface,
                  )
                : c.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? a : c.line,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon3D(icon, active: selected, size: 48),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: Motion.micro,
                    opacity: selected ? 1 : 0,
                    child: Icon(Icons.check_circle_rounded, color: a, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: context.text.bodySmall?.copyWith(color: c.inkMuted),
                ),
              if (trailing != null) ...[
                const SizedBox(height: Space.xs),
                Text(
                  trailing!,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays [children] out [cols] per row; tiles grow with long translations and large fonts.
Widget tileRows(List<Widget> children, {int cols = 2}) => Column(
  children: [
    for (var i = 0; i < children.length; i += cols)
      Padding(
        padding: const EdgeInsets.only(bottom: Space.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = i; j < i + cols; j++) ...[
              if (j > i) const SizedBox(width: Space.xs),
              Expanded(
                child: j < children.length
                    ? children[j]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
  ],
);

/// Bottom bar of the design: amount + small caption on the left, primary action on the right.
class PriceBar extends StatelessWidget {
  const PriceBar({
    super.key,
    required this.amount,
    required this.label,
    required this.onPressed,
    this.caption,
    this.busy = false,
  });
  final int amount;
  final String? caption;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => BottomActionBar(
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plain text: RollingAmount lays out a digit column that outgrows the bar at 200% text.
              Text(
                context.won(amount),
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: PrimaryButton(label: label, busy: busy, onPressed: onPressed),
        ),
      ],
    ),
  );
}
