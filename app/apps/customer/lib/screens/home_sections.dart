part of 'home.dart';

/// Eight tiles, four to a row, in the catalogue's own order.
class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.services});
  final List<Service> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const Skeleton(height: 200);
    return Column(
      children: [
        for (var row = 0; row < services.length; row += _gridColumns)
          // Rows, not a fixed-ratio grid: a label that wraps makes its row taller instead of clipping.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = row; i < row + _gridColumns; i++)
                Expanded(
                  child: i < services.length
                      ? _ServiceTile(service: services[i], index: i)
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.index});
  final Service service;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final code = service.code;
    final name = t.service(code);
    final badge = switch (service.content['badge']) {
      'new' => t.dhBadgeNew,
      'hot' => t.dhBadgeHot,
      _ => null,
    };
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ServiceScreen(service: service)),
    );
    return StaggerIn(
      index: index,
      step: _tileStep,
      child: Semantics(
        button: true,
        label: badge == null ? name : '$name, $badge',
        onTap: open,
        excludeSemantics: true,
        child: Pressable(
          radius: BorderRadius.circular(Radii.tile),
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: Space.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: _plate,
                      height: _plate,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.surfaceHigh,
                        borderRadius: BorderRadius.circular(Radii.tile),
                      ),
                      // Flies the art into the service screen.
                      child: Hero(
                        tag: 'svc-$code',
                        child: Icon3D(
                          'svc_$code',
                          size: _tileArt,
                          idle: Icon3DIdle.float,
                        ),
                      ),
                    ),
                    if (badge != null)
                      PositionedDirectional(
                        top: -6,
                        end: -8,
                        child: _TileBadge(
                          label: badge,
                          after: _tileStep * index,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(
                  name,
                  style: context.text.labelMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Red N / HOT pill on a tile's corner. Pops in once, after its tile has arrived.
class _TileBadge extends StatelessWidget {
  const _TileBadge({required this.label, required this.after});
  final String label;
  final Duration after;

  @override
  Widget build(BuildContext context) {
    final wait = after + Motion.route;
    final total = wait + Motion.iconPop;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motionFor(context, total),
      curve: Interval(
        wait.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutBack,
      ),
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Semantic.danger,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: context.colors.surface, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _badgeSize,
            minHeight: _badgeSize,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              // The pill is a fixed-size mark on the art, like the art itself.
              child: MediaQuery.withNoTextScaling(
                child: Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAddressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.primaryTint,
    level: Level.flat,
    onTap: () => showAddressForm(context),
    child: Row(
      children: [
        Icon(Icons.add_location_alt_rounded, color: context.primary, size: 32),
        const SizedBox(width: Space.md),
        Expanded(
          child: Text(context.t.homeAddAddress, style: context.text.bodyMedium),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class _RebookCard extends StatelessWidget {
  const _RebookCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final s = context.app.service(booking.serviceCode);
    return AppCard(
      level: Level.flat,
      border: context.colors.line,
      onTap: s == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ServiceScreen(
                  service: s,
                  initialUnit: booking.unitIndex,
                  initialCounts: booking.countsOf(s.units.length),
                ),
              ),
            ),
      child: Row(
        children: [
          ServiceGlyph(booking.serviceCode, size: 48),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.homeRebook(context.t.service(booking.serviceCode)),
                  style: context.text.titleSmall,
                ),
                Text(context.t.homeRebookBody, style: context.text.bodySmall),
              ],
            ),
          ),
          Icon(Icons.replay_rounded, color: context.primary),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final items = [
      (Icons.receipt_long_rounded, t.trustVat, ServiceHues.moveOut),
      (Icons.event_available_rounded, t.trustCancel, ServiceHues.bathroom),
      (Icons.shield_rounded, t.trustCard, ServiceHues.mattress),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.xs),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(Space.sm),
                level: Level.flat,
                border: context.colors.line,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TrustBadge(icon: items[i].$1, hue: items[i].$3),
                    const SizedBox(height: 8),
                    Text(
                      items[i].$2,
                      style: context.text.labelSmall?.copyWith(
                        color: context.colors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Clay badge for trust rows: gradient tile in the hue, inner highlight, glow.
class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.hue});
  final IconData icon;
  final ServiceHue hue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = c.isDark ? hue.tint : hue.tone;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(base, Colors.white, 0.3)!, base],
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: c.isDark ? 0.35 : 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 19,
        color: c.isDark ? const Color(0xFF070B16) : Colors.white,
      ),
    );
  }
}
