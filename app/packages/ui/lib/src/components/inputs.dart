import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens.dart';
import 'interactive.dart';

/// Big tappable radio row: title, subtitle, trailing value. Used for options and pickers.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.leading,
    this.enabled = true,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? leading;
  final bool selected;
  final bool enabled;
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
      enabled: enabled,
      child: Pressable(
        enabled: enabled,
        onTap: onTap,
        radius: radius,
        shadows: selected && c.isDark
            ? [
                BoxShadow(
                  color: a.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: -6,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
        child: AnimatedContainer(
          duration: Motion.standard,
          curve: Motion.ease,
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    a.withValues(alpha: c.isDark ? 0.18 : 0.08),
                    c.surface,
                  )
                : c.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? a : c.line,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.md,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: Space.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.text.titleSmall),
                        if (subtitle != null)
                          Text(subtitle!, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(width: Space.sm),
                  AnimatedSwitcher(
                    duration: Motion.micro,
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(selected),
                      color: selected ? a : c.inkMuted,
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

/// Minus / value / plus with a range; announces value to screen readers.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 5,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, int next, bool enabled, String tip) =>
        IconButton.filledTonal(
          tooltip: tip,
          onPressed: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(next);
                }
              : null,
          icon: Icon(icon),
        );
    return Row(
      children: [
        Expanded(child: Text(label, style: context.text.titleSmall)),
        btn(Icons.remove_rounded, value - 1, value > min, '−'),
        SizedBox(
          width: 44,
          child: Semantics(
            liveRegion: true,
            label: '$label $value',
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
          ),
        ),
        btn(Icons.add_rounded, value + 1, value < max, '+'),
      ],
    );
  }
}

/// Row of choice chips (single select).
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.xs,
    runSpacing: Space.xs,
    children: [
      for (final (v, label) in options)
        ChoiceChip(
          label: Text(label),
          selected: v == value,
          showCheckmark: false,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
    ],
  );
}

/// Yes / no segmented control with required marker.
class YesNo extends StatelessWidget {
  const YesNo({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.yes,
    required this.no,
  });
  final String label;
  final bool? value;
  final ValueChanged<bool> onChanged;
  final String yes;
  final String no;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.text.titleSmall),
      const SizedBox(height: Space.xs),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        emptySelectionAllowed: true,
        segments: [
          ButtonSegment(value: true, label: Text(yes)),
          ButtonSegment(value: false, label: Text(no)),
        ],
        selected: value == null ? {} : {value!},
        onSelectionChanged: (s) => s.isEmpty ? null : onChanged(s.first),
      ),
    ],
  );
}
