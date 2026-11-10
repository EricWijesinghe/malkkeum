import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import '../tokens.dart';

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

/// A colored rounded square holding the service glyph.
class ServiceGlyph extends StatelessWidget {
  const ServiceGlyph(this.code, {super.key, this.size = 56});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = ServiceHues.of(code);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: context.colors.tintOf(hue), borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(serviceIcon(code), size: size * 0.5, color: context.colors.isDark ? hue.tint : hue.tone),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(Space.lg), this.onTap, this.color, this.border});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Radii.card);
    return Material(
      color: color ?? context.colors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: border == null ? null : BoxDecoration(borderRadius: radius, border: Border.all(color: border!, width: 1.5)),
          child: child,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.label});
  final int status;
  final String label;

  @override
  Widget build(BuildContext context) => Tag(label: label, hue: StatusHues.of(status));
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
      decoration: BoxDecoration(color: context.colors.tintOf(hue), borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
        Text(label, style: context.text.labelMedium?.copyWith(color: fg, fontSize: 12)),
      ]),
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
        child: Row(children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: context.text.titleMedium))),
          ?trailing,
        ]),
      );
}

/// Primary CTA with built-in busy state so double taps can't double charge.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false, this.color});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Color? color;

  @override
  Widget build(BuildContext context) => FilledButton(
        style: color == null ? null : FilledButton.styleFrom(backgroundColor: color),
        onPressed: busy ? null : onPressed,
        child: AnimatedSwitcher(
          duration: Motion.micro,
          child: busy
              ? const SizedBox(key: ValueKey('busy'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(label, key: const ValueKey('label')),
        ),
      );
}

/// Sticky bottom area: optional summary line above the CTA.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child, this.summary});
  final Widget child;
  final Widget? summary;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: context.colors.surface, border: Border(top: BorderSide(color: context.colors.line))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.sm),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (summary != null) ...[summary!, const SizedBox(height: Space.sm)],
              child,
            ]),
          ),
        ),
      );
}

/// Segmented progress for multi-step flows.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.total, this.color});
  final int current;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$current / $total',
        child: Row(children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: Motion.standard,
                curve: Motion.ease,
                height: 4,
                decoration: BoxDecoration(color: i < current ? (color ?? context.primary) : context.colors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action, this.hue});
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final ServiceHue? hue;

  @override
  Widget build(BuildContext context) {
    final h = hue ?? ServiceHues.bathroom;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: context.colors.tintOf(h), shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: context.colors.isDark ? h.tint : h.tone),
          ),
          const SizedBox(height: Space.lg),
          Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[const SizedBox(height: Space.xs), Text(body!, style: context.text.bodySmall, textAlign: TextAlign.center)],
          if (action != null) ...[const SizedBox(height: Space.xl), action!],
        ]),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.retryLabel, required this.onRetry});
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: message,
        hue: StatusHues.cancelled,
        action: OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
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

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: reduce ? const AlwaysStoppedAnimation(0.7) : Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(height: widget.height, decoration: BoxDecoration(color: context.colors.line, borderRadius: BorderRadius.circular(widget.radius))),
    );
  }
}

Future<T?> showAppSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md), child: Text(title, style: ctx.text.titleLarge)),
          Flexible(child: builder(ctx)),
        ]),
      ),
    );

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
