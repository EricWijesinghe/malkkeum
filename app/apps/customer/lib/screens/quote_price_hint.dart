import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// The quote price before any address or visit time is chosen (no sign-up needed to see it).
/// Shows nothing when the estimate fails: the later estimate step reports the error.
class QuotePriceHint extends StatelessWidget {
  const QuotePriceHint({super.key, required this.estimate});
  final Future<Json>? estimate;

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: estimate,
    builder: (context, snap) {
      if (snap.hasError) return const SizedBox.shrink();
      final e = snap.data;
      if (e == null) return const Skeleton(height: 72);
      final total = (e['total'] as num? ?? 0).toInt();
      final t = context.t;
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.sm,
        ),
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: context.colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.guestPriceLine(context.won(total)),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                t.guestPeakNote,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
