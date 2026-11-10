import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'addresses.dart';
import 'booking_detail.dart';
import 'more.dart';
import 'service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Booking> _bookings = const [];
  List<ContentItem> _banners = const [];
  List<ContentItem> _notices = const [];
  int _seenVersion = -1;

  Future<void> _load() async {
    final api = context.api;
    final results = await Future.wait([
      api.get('/bookings'),
      api.get('/content', query: {'kind': 'banner'}),
      api.get('/content', query: {'kind': 'notice'}),
    ]);
    if (!mounted) return;
    setState(() {
      _bookings = (results[0] as List)
          .map((e) => Booking.fromJson(e as Json))
          .toList();
      _banners = (results[1] as List)
          .map((e) => ContentItem(e as Json))
          .toList();
      _notices = (results[2] as List)
          .map((e) => ContentItem(e as Json))
          .take(3)
          .toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.app.bookingsVersion;
    if (v != _seenVersion) {
      _seenVersion = v;
      _load().catchError((_) {});
    }
  }

  Booking? get _next {
    final active = _bookings.where((b) => b.isActive).toList()
      ..sort((a, b) => a.visitStart.compareTo(b.visitStart));
    return active.firstOrNull;
  }

  Booking? get _lastDone =>
      _bookings.where((b) => b.status == 3 && !b.isQuote).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    final next = _next;
    final last = _lastDone;
    final usableCoupons = app.coupons.where((c) => c.usable).length;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_load(), app.loadCoupons(), app.loadAddresses()]);
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            titleSpacing: Space.gutter,
            centerTitle: false,
            title: _AddressChip(addresses: app.addresses),
            actions: [
              IconButton(
                tooltip: t.moreNotices,
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ContentListScreen(kind: 'notice', title: t.moreNotices),
                  ),
                ),
              ),
              const SizedBox(width: Space.xs),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.xs,
              Space.gutter,
              Space.xxxl,
            ),
            sliver: SliverList.list(
              children: [
                StaggerIn(
                  index: 0,
                  child: Text(
                    app.name.isEmpty
                        ? t.homeGreetingAnon
                        : t.homeGreeting(app.name),
                    style: context.text.headlineSmall,
                  ),
                ),
                const SizedBox(height: Space.lg),
                if (next != null) ...[
                  StaggerIn(index: 1, child: _UpcomingCard(booking: next)),
                  const SizedBox(height: Space.md),
                ],
                if (app.addresses.isEmpty && app.services.isNotEmpty) ...[
                  _AddAddressCard(),
                  const SizedBox(height: Space.md),
                ],
                StaggerIn(
                  index: 2,
                  child: _ServiceGrid(services: app.services),
                ),
                const SizedBox(height: Space.md),
                if (usableCoupons > 0 || _banners.isNotEmpty)
                  StaggerIn(
                    index: 3,
                    child: _CouponBanner(
                      count: usableCoupons,
                      banner: _banners.firstOrNull,
                    ),
                  ),
                if (last != null && next == null) ...[
                  const SizedBox(height: Space.md),
                  _RebookCard(booking: last),
                ],
                const SizedBox(height: Space.lg),
                const StaggerIn(index: 4, child: _TrustRow()),
                if (_notices.isNotEmpty) ...[
                  const SizedBox(height: Space.xl),
                  SectionTitle(t.homeNotices),
                  for (final n in _notices)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        n.title(context.lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ContentDetailScreen(item: n),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.addresses});
  final List<Address> addresses;

  @override
  Widget build(BuildContext context) {
    final a = addresses.firstOrNull;
    final label = a == null
        ? context.t.homeAddAddressCta
        : '${a.label} · ${districtByCode(a.districtCode)?.name(context.lang) ?? ''}';
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.chip),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AddressesScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_rounded, color: context.primary, size: 20),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: context.text.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

/// Hero card: aurora mesh over the deep brand blue, tilts on hover, springs on press.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = booking;
    final days = DateUtils.dateOnly(
      b.visitDate,
    ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final steps = b.isQuote ? 4 : 3;
    final done = b.isQuote ? b.status + 1 : b.status;
    final radius = BorderRadius.circular(Radii.card);
    final deep = BrandConfig.placeholder.primaryDeep;
    final statusGlow = StatusHues.of(b.status).tone;
    return Tilt3D(
      radius: radius,
      child: Pressable(
        radius: radius,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookingDetailScreen(id: b.id),
          ),
        ),
        shadows: Depth.of(
          context.colors,
          Level.raised,
          glow: context.colors.isDark ? statusGlow : deep,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            color: deep,
            child: AuroraBackground(
              colors: const [
                Color(0xFF5B7BFF),
                Color(0xFF12B48F),
                Color(0xFFFFB400),
              ],
              child: Stack(
                children: [
                  Positioned(
                    right: -24,
                    top: -24,
                    child: Icon(
                      serviceIcon(b.serviceCode),
                      size: 140,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${t.homeUpcoming} · ${days <= 0 ? t.today : t.dDay('$days')}',
                              style: context.text.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(Radii.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _LiveDot(),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.status(b.status),
                                    style: context.text.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.sm),
                        Text(
                          '${dateLabel(b.visitDate, context.lang)} ${hourLabel(b.startHour, context.lang)}',
                          style: context.text.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            t.service(b.serviceCode),
                            if (b.teamName != null) b.teamName!,
                          ].join(' · '),
                          style: context.text.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        StepProgress(
                          current: done,
                          total: steps,
                          color: BrandConfig.placeholder.sun,
                        ),
                      ],
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

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.services});
  final List<Service> services;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        Space.sm,
        Space.lg,
        Space.sm,
        Space.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs),
            child: SectionTitle(t.homeServices),
          ),
          if (services.isEmpty)
            const Padding(
              padding: EdgeInsets.all(Space.xs),
              child: Skeleton(height: 180),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 0.70,
              mainAxisSpacing: Space.xs,
              children: [
                for (final s in services)
                  Semantics(
                    label: t.service(s.code),
                    child: Tilt3D(
                      maxAngle: 0.10,
                      radius: BorderRadius.circular(Radii.tile),
                      child: Pressable(
                        radius: BorderRadius.circular(Radii.tile),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ServiceScreen(service: s),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'svc-${s.code}',
                              child: ServiceGlyph(s.code, size: 58),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.serviceShort(s.code),
                              style: context.text.labelMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Price is visible on the tile itself, in the service hue.
                            // Scale the tag down rather than let neighbours collide on narrow phones.
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Tag(
                                  label: s.isQuote
                                      ? t.quoteBadge
                                      : t.fromPrice(context.won(s.fromPrice ?? 0)),
                                  hue: ServiceHues.of(s.code),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AddAddressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.primaryTint,
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddressFormScreen())),
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

class _CouponBanner extends StatelessWidget {
  const _CouponBanner({required this.count, this.banner});
  final int count;
  final ContentItem? banner;

  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.sunTint,
    glow: context.colors.sun,
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CouponsScreen())),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(context.colors.sun, Colors.white, 0.25)!,
                context.colors.sun,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: context.colors.sun.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.confirmation_number_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banner?.title(context.lang) ?? context.t.moreCoupons,
                style: context.text.titleSmall,
              ),
              if (count > 0)
                Text(
                  context.t.couponAvailable('$count'),
                  style: context.text.bodySmall,
                ),
            ],
          ),
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
      onTap: s == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ServiceScreen(service: s, initialUnit: booking.unitIndex),
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

/// Pulsing dot that says "this booking is live". Frozen under reduced motion.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) {
      final pulse = Curves.easeOut.transform(_c.value);
      return SizedBox.square(
        dimension: 10,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 8 * pulse,
              height: 6 + 8 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF5EEAD4,
                ).withValues(alpha: 0.6 * (1 - pulse)),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF5EEAD4),
              ),
              child: SizedBox(width: 6, height: 6),
            ),
          ],
        ),
      );
    },
  );
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
