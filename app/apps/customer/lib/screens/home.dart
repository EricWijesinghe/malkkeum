import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../src/u1_stub.dart'; // u1-stub: delete when U1 lands
import '../state.dart';
import 'addresses.dart';
import 'booking_detail.dart';
import 'content_rail.dart';
import 'feed.dart';
import 'growth.dart';
import 'more.dart';
import 'notifications.dart';
import 'quote_flow.dart';
import 'service.dart';

/// Rail length on home; "see all" opens the full list.
const _railItems = 8;

/// Text on the yellow banner: the fill is the same in light and dark, so the ink is fixed too.
const _onSun = Neutral.c900;

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
  List<ContentItem> _news = const [];
  List<ContentItem> _tips = const [];
  List<Json> _feed = const [];
  bool _loaded = false;
  int _unread = 0;
  int _seenVersion = -1;

  /// The feed from the last session paints first; the network answer then replaces it.
  @override
  void initState() {
    super.initState();
    _restoreFeed();
  }

  String get _feedKey =>
      Deps.read(context).session.signedIn ? 'feed.me' : 'feed.guest';

  Future<void> _restoreFeed() async {
    final cached = await context.appRead.cache.read(_feedKey);
    if (!mounted || _loaded || cached is! List) return;
    setState(() => _feed = cached.cast<Json>());
  }

  /// Guests see the public feed and content; account data loads only when signed in.
  Future<void> _load() async {
    final api = context.api;
    final signedIn = Deps.read(context).session.signedIn;
    if (signedIn) {
      unreadAlerts(api).then((n) {
        if (mounted) setState(() => _unread = n);
      }).ignore();
    }
    final district = context.app.addresses.firstOrNull?.districtCode;
    final results = await Future.wait([
      signedIn ? api.get('/bookings') : Future.value(const <Json>[]),
      api.get('/content', query: {'kind': 'banner'}),
      api.get('/content', query: {'kind': 'notice'}),
      api.get(signedIn ? '/me/feed' : '/feed', query: {'district': district}),
      api.get('/content', query: {'kind': 'news'}),
      api.get('/content', query: {'kind': 'tip'}),
    ]);
    if (!mounted) return;
    List<ContentItem> rail(Object? rows) => (rows as List)
        .map((e) => ContentItem(e as Json))
        .take(_railItems)
        .toList();
    final feed = ((results[3] as Json)['cards'] as List).cast<Json>();
    unawaited(context.appRead.cache.write(_feedKey, feed));
    setState(() {
      _loaded = true;
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
      _feed = feed;
      _news = rail(results[4]);
      _tips = rail(results[5]);
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
    final signedIn = Deps.of(context).session.signedIn;
    // Banner content linking to a service is a recommendation; the first other banner is the hero.
    final picks = _banners.where((b) => pickServiceCode(b) != null).toList();
    final hero = _banners.where((b) => pickServiceCode(b) == null).firstOrNull;
    return RefreshIndicator(
      color: context.primary,
      backgroundColor: context.colors.surface,
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
                tooltip: _unread > 0 ? t.nUnread('$_unread') : t.nAlerts,
                icon: Badge(
                  isLabelVisible: _unread > 0,
                  label: Text('$_unread'),
                  child: const Icon3D('ui_bell', size: 28),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  if (mounted) setState(() => _unread = 0);
                },
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
                  child: _GreetingHeader(
                    text: app.name.isEmpty
                        ? timeGreeting(t, DateTime.now())
                        : t.homeGreeting(app.name),
                  ),
                ),
                const SizedBox(height: Space.lg),
                if (next != null) ...[
                  StaggerIn(index: 1, child: _UpcomingCard(booking: next)),
                  const SizedBox(height: Space.md),
                ],
                // Brief order: banner, 7 categories, recommended, news, tips.
                if (usableCoupons > 0 || hero != null) ...[
                  StaggerIn(
                    index: 2,
                    child: _HeroBanner(count: usableCoupons, banner: hero),
                  ),
                  const SizedBox(height: Space.md),
                ],
                if (signedIn &&
                    app.addresses.isEmpty &&
                    app.services.isNotEmpty) ...[
                  _AddAddressCard(),
                  const SizedBox(height: Space.md),
                ],
                StaggerIn(
                  index: 3,
                  child: _ServiceGrid(services: app.services),
                ),
                const SizedBox(height: Space.lg),
                FeedSection(cards: _feed, picks: picks, loading: !_loaded),
                const SizedBox(height: Space.md),
                ContentRail(
                  title: t.dhHomeNews,
                  kind: 'news',
                  items: _news,
                  art: 'news_megaphone',
                ),
                if (_news.isNotEmpty) const SizedBox(height: Space.lg),
                ContentRail(
                  title: t.moreTips,
                  kind: 'tip',
                  items: _tips,
                  art: 'tip_bulb',
                ),
                if (last != null && next == null) ...[
                  const SizedBox(height: Space.md),
                  _RebookCard(booking: last),
                ],
                const SizedBox(height: Space.lg),
                const SocialProofCard(),
                const SizedBox(height: Space.md),
                if (signedIn)
                  const ReferralCard()
                else
                  _GuestReferralGate(onSignedIn: _load),
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

/// Greeting by local time of day; the name replaces it once the account has one.
String timeGreeting(T t, DateTime now) {
  final h = now.hour;
  if (h < 12) return t.greetMorning;
  if (h < 18) return t.greetAfternoon;
  return t.greetEvening;
}

/// Greeting over a wash that shifts with the time of day (sunrise, afternoon, dusk).
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final c = context.colors;
    final top = h < 12
        ? c.sunTint
        : (h < 18 ? c.primaryTint : c.tintOf(ServiceHues.of('studio')));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, c.canvas],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Text(text, style: context.text.headlineSmall),
      ),
    );
  }
}

/// Referral needs an account. Tapping asks for sign-in, then shows the real card in place.
class _GuestReferralGate extends StatelessWidget {
  const _GuestReferralGate({required this.onSignedIn});
  final Future<void> Function() onSignedIn;

  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.primaryTint,
    onTap: () async {
      if (!await requireSignIn(context) || !context.mounted) return;
      await onSignedIn();
    },
    child: Row(
      children: [
        Icon(Icons.card_giftcard_rounded, color: context.primary, size: 28),
        const SizedBox(width: Space.md),
        Expanded(
          child: Text(context.t.referralTitle, style: context.text.bodyMedium),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
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
      // 48 dp minimum touch target (Android / WCAG).
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(child: Icon3D('ui_pin', size: 24)),
            const SizedBox(width: 6),
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
    final days = DateUtils.dateOnly(b.visitDate)
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
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
                            Expanded(
                              child: Text(
                                '${t.homeUpcoming} · ${days <= 0 ? t.today : t.dDay('$days')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.xs),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(
                                    Radii.pill,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _LiveDot(),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        t.status(b.status),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.text.labelMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
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

const _moveCodes = {'move_in', 'move_out'};

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.services});
  final List<Service> services;

  static String _tag(BuildContext context, Service s) => s.isQuote
      ? context.t.quoteBadge
      : context.t.fromPrice(context.won(s.fromPrice ?? 0));

  static void _open(BuildContext context, Service s) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => ServiceScreen(service: s)));

  /// The merged move tile asks which clean it is, then goes straight into that quote.
  static Future<void> _pickMove(
    BuildContext context,
    List<Service> moves,
  ) async {
    final t = context.t;
    final picked = await showAppSheet<Service>(
      context,
      title: t.dhMovePickTitle,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        children: [
          for (final s in moves)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: OptionCard(
                leading: ExcludeSemantics(
                  child: Icon3D('svc_${s.code}', size: 44),
                ),
                title: t.service(s.code),
                subtitle: t.serviceDesc(s.code),
                selected: false,
                onTap: () => Navigator.of(ctx).pop(s),
              ),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => picked.isQuote
            ? QuoteFlowScreen(service: picked)
            : ServiceScreen(service: picked),
      ),
    );
  }

  /// Move-in and move-out share one tile (7 categories); a catalogue with only one keeps its own tile.
  List<Widget> _tiles(BuildContext context) {
    final t = context.t;
    final moves = services.where((s) => _moveCodes.contains(s.code)).toList();
    final merge = moves.length == _moveCodes.length;
    final shown = merge
        ? services.where(
            (s) => !_moveCodes.contains(s.code) || s == moves.first,
          )
        : services;
    return [
      for (final s in shown)
        if (merge && s == moves.first)
          _ServiceTile(
            art: 'svc_move',
            name: t.dhSvcMove,
            short: t.dhSvcMoveShort,
            tag: _tag(context, s),
            hue: ServiceHues.of(s.code),
            onTap: () => _pickMove(context, moves),
          )
        else
          _ServiceTile(
            art: 'svc_${s.code}',
            heroTag: 'svc-${s.code}',
            name: t.service(s.code),
            short: t.serviceShort(s.code),
            tag: _tag(context, s),
            hue: ServiceHues.of(s.code),
            onTap: () => _open(context, s),
          ),
    ];
  }

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
              children: _tiles(context),
            ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.art,
    required this.name,
    required this.short,
    required this.tag,
    required this.hue,
    required this.onTap,
    this.heroTag,
  });
  final String art;
  final String name;
  final String short;
  final String tag;
  final ServiceHue hue;
  final VoidCallback onTap;

  /// Flies the art into the service screen; the merged tile has no single destination.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final icon = Icon3D(art, size: 58);
    return Semantics(
      label: name,
      child: Tilt3D(
        maxAngle: 0.10,
        radius: BorderRadius.circular(Radii.tile),
        child: Pressable(
          radius: BorderRadius.circular(Radii.tile),
          onTap: onTap,
          // Large system fonts scale the tile down instead of overflowing it. The fixed
          // width keeps every tile the same size; only height can trigger the scaling.
          child: LayoutBuilder(
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: box.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (heroTag == null)
                      icon
                    else
                      Hero(tag: heroTag!, child: icon),
                    const SizedBox(height: 6),
                    Text(
                      short,
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
                        child: Tag(label: tag, hue: hue),
                      ),
                    ),
                  ],
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

/// Full-width hero above the grid: yellow fill, ink text, coupon art. The headline is the console's
/// banner content (e.g. the welcome coupon); with no banner it names the customer's usable coupons.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.count, this.banner});
  final int count;
  final ContentItem? banner;

  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.sun,
    glow: context.colors.sun,
    onTap: () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const CouponsScreen())),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banner?.title(context.lang) ?? context.t.moreCoupons,
                style: context.text.titleLarge?.copyWith(color: _onSun),
              ),
              if (count > 0) ...[
                const SizedBox(height: Space.xs),
                Text(
                  context.t.couponAvailable('$count'),
                  style: context.text.bodySmall?.copyWith(color: _onSun),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: Space.md),
        const ExcludeSemantics(child: Icon3D('banner_coupon', size: 64)),
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
                color: const Color(0xFF5EEAD4)
                    .withValues(alpha: 0.6 * (1 - pulse)),
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
