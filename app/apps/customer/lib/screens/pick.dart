import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'service.dart';

const _popularCount = 4;
const _popularArt = 44.0;

/// PICK's service list: the first catalogue services in the owner's order, each with its price.
// shortcut: the API has no booking counts yet, so "popular" is the owner's catalogue order;
// upgrade by sorting on bookings per service once /services returns them.
class PopularServices extends StatelessWidget {
  const PopularServices({super.key, required this.services});

  final List<Service> services;

  @override
  Widget build(BuildContext context) {
    final shown = services.take(_popularCount).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final t = context.t;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.xl),
        Semantics(
          header: true,
          child: Text(t.popularServices, style: context.text.titleLarge),
        ),
        for (final s in shown)
          InkWell(
            borderRadius: BorderRadius.circular(Radii.card),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ServiceScreen(service: s),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon3D('svc_${s.code}', size: _popularArt),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.service(s.code), style: context.text.titleSmall),
                        Text(
                          s.isQuote
                              ? t.quoteBadge
                              : t.fromPrice(context.won(s.fromPrice ?? 0)),
                          style: context.text.bodySmall?.copyWith(
                            color: c.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: c.inkMuted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
