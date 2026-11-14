import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'flow_widgets.dart';

/// Option cards for a counts service (design p08): two per row, icon, name, duration, price.
/// Options taken several times get a −/+ stepper; options taken once (max_each 1) toggle on tap.
class CountsGrid extends StatelessWidget {
  const CountsGrid({
    super.key,
    required this.service,
    required this.counts,
    required this.onChanged,
  });
  final Service service;

  /// One count per option, catalogue order. Shorter lists read as zero.
  final List<int> counts;
  final ValueChanged<List<int>> onChanged;

  void _set(int index, int value) => onChanged([
    for (var i = 0; i < service.units.length; i++)
      if (i == index) value else (i < counts.length ? counts[i] : 0),
  ]);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return tileRows([
      for (final (i, u) in service.units.indexed)
        _CountTile(
          icon: service.code == 'aircon'
              ? 'ac_${u.labelKey}'
              : 'svc_${service.code}',
          label: t.unit(u.labelKey),
          subtitle: t.duration(u.minutes),
          trailing: context.won(u.price),
          count: i < counts.length ? counts[i] : 0,
          cap: service.countCap,
          toggle: service.isMultiSelect,
          onChanged: (n) => _set(i, n),
        ),
    ]);
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.trailing,
    required this.count,
    required this.cap,
    required this.toggle,
    required this.onChanged,
  });
  final String icon;
  final String label;
  final String subtitle;
  final String trailing;
  final int count;
  final int cap;

  /// Tap the whole card to pick it once (no stepper).
  final bool toggle;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = context.primary;
    final selected = count > 0;
    final radius = BorderRadius.circular(Radii.tile);
    final body = AnimatedContainer(
      duration: motionFor(context, Motion.standard),
      curve: Motion.ease,
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
              ExcludeSemantics(child: Icon3D(icon, active: selected, size: 48)),
              const Spacer(),
              PopIn(
                show: selected,
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
          Text(
            subtitle,
            style: context.text.bodySmall?.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.xs),
          Text(
            trailing,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!toggle) ...[
            const SizedBox(height: Space.xs),
            _Stepper(count: count, cap: cap, onChanged: onChanged),
          ],
        ],
      ),
    );
    if (!toggle) return body;
    return Semantics(
      button: true,
      toggled: selected,
      child: Pressable(
        onTap: () => onChanged(selected ? 0 : 1),
        radius: radius,
        child: body,
      ),
    );
  }
}

/// −  n  + under the card's price; the buttons keep 48dp targets.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.count,
    required this.cap,
    required this.onChanged,
  });
  final int count;
  final int cap;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: t.countMinus,
          icon: const Icon(Icons.remove_rounded),
          onPressed: count > 0 ? () => onChanged(count - 1) : null,
        ),
        Text(
          '$count',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        IconButton(
          tooltip: t.countPlus,
          icon: const Icon(Icons.add_rounded),
          onPressed: count < cap ? () => onChanged(count + 1) : null,
        ),
      ],
    );
  }
}
