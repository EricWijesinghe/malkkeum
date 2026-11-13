import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'addresses.dart';
import 'bookings.dart' show BookingCard;
import 'content_rail.dart';
import 'feed.dart';
import 'growth.dart';
import 'notifications.dart';
import 'service.dart';

/// The header holds a 48dp segmented toggle.
const _toolbarHeight = 64.0;
const _logoSize = 28.0;
const _toggleMaxWidth = 220.0;

/// Header chrome stops growing here; the page content follows the system text size in full.
const _headerMaxTextScale = 1.3;
const _bellDot = 7.0;

const _gridColumns = 4;
const _plate = 64.0;
const _tileArt = 44.0;
const _tileStep = Duration(milliseconds: 30);
const _badgeSize = 22.0;

enum _HomeView { all, pick }

/// One home section's answer, or null when its request or its parsing fails ([onError] gets the
/// cause). Each section settles on its own, so one failed list never holds back the others.
Future<V?> _section<V>(
  Future<Object?> request,
  V Function(Object?) parse, {
  void Function(Object error)? onError,
}) async {
  try {
    return parse(await request);
  } catch (e) {
    onError?.call(e);
    return null;
  }
}

// shortcut: the API sends no date, so news and tips alternate (each newest first);
// sort by date once /content returns created_at.
List<ContentItem> _alternate(List<ContentItem> news, List<ContentItem> tips) =>
    [
      for (var i = 0; i < news.length || i < tips.length; i++) ...[
        if (i < news.length) news[i],
        if (i < tips.length) tips[i],
      ],
    ].take(newsListMax).toList();

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Booking> _bookings = const [];
  List<ContentItem> _banners = const [];
  ContentItem? _notice;
  List<ContentItem> _articles = const [];
  List<Json> _feed = const [];
  bool _loaded = false;

  /// Why the last load could not get the bookings or the feed; null once a load gets both.
  Object? _error;
  int _unread = 0;
  int _seenVersion = -1;
  _HomeView _view = _HomeView.all;

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
    // Only the bookings and the feed raise the error card; a missing banner or tip list just stays out.
    Object? failure;
    void vital(Object e) => failure ??= e;
    List<ContentItem> items(Object? rows) =>
        (rows as List).map((e) => ContentItem(e as Json)).toList();
    Future<List<ContentItem>?> content(String kind) =>
        _section(api.get('/content', query: {'kind': kind}), items);
    final (bookings, feed, banners, notice, news, tips) = await (
      _section(
        signedIn ? api.get('/bookings') : Future.value(const <Json>[]),
        (r) => (r as List).map((e) => Booking.fromJson(e as Json)).toList(),
        onError: vital,
      ),
      _section(
        api.get(signedIn ? '/me/feed' : '/feed', query: {'district': district}),
        (r) => ((r as Json)['cards'] as List).cast<Json>(),
        onError: vital,
      ),
      content('banner'),
      content('notice'),
      content('news'),
      content('tip'),
    ).wait;
    if (!mounted) return;
    if (feed != null) unawaited(context.appRead.cache.write(_feedKey, feed));
    setState(() {
      _loaded = true;
      _error = failure;
      // A section that failed keeps what it showed before.
      _bookings = bookings ?? _bookings;
      _banners = banners ?? _banners;
      if (notice != null) _notice = notice.firstOrNull;
      if (news != null || tips != null) {
        _articles = _alternate(news ?? const [], tips ?? const []);
      }
      _feed = feed ?? _feed;
    });
  }

  /// Inline, so the rest of home stays usable; retry runs the whole load again.
  Widget _errorCard(Object error) => ErrorRetry(
    compact: true,
    message: context.t.error(error),
    retryLabel: context.t.retry,
    onRetry: _load,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.app.bookingsVersion;
    if (v != _seenVersion) {
      _seenVersion = v;
      unawaited(_load());
    }
  }

  Booking? get _next {
    final active = _bookings.where((b) => b.isActive).toList()
      ..sort((a, b) => a.visitStart.compareTo(b.visitStart));
    return active.firstOrNull;
  }

  Booking? get _lastDone =>
      _bookings.where((b) => b.status == 3 && !b.isQuote).firstOrNull;

  Future<void> _openAlerts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
    if (mounted) setState(() => _unread = 0);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    final c = context.colors;
    // Banner content linking to a service is a recommendation; the others page in the carousel.
    final picks = _banners.where((b) => pickServiceCode(b) != null).toList();
    return RefreshIndicator(
      color: context.primary,
      backgroundColor: c.surface,
      onRefresh: () async {
        await Future.wait([_load(), app.loadCoupons(), app.loadAddresses()]);
      },
      child: CustomScrollView(
        // The PICK view can be shorter than the screen and must still pull to refresh.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: c.surface,
            toolbarHeight: _toolbarHeight,
            titleSpacing: Space.gutter,
            centerTitle: false,
            title: _HeaderTitle(
              view: _view,
              onView: (v) => setState(() => _view = v),
            ),
            actions: [
              IconButton(
                tooltip: _unread > 0 ? t.nUnread('$_unread') : t.nAlerts,
                // A dot, not a count: the list behind the bell has the detail.
                icon: Badge(
                  isLabelVisible: _unread > 0,
                  smallSize: _bellDot,
                  backgroundColor: Semantic.danger,
                  child: Icon3D('ui_bell', size: 28, attention: _unread),
                ),
                onPressed: _openAlerts,
              ),
              const SizedBox(width: Space.xs),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeThroughSwitcher(
              child: _view == _HomeView.pick
                  ? _pickView(picks)
                  : _allView(picks),
            ),
          ),
        ],
      ),
    );
  }

  /// Design order: grid, recommended, banner, news. What the design does not show comes last.
  Widget _allView(List<ContentItem> picks) {
    final app = context.app;
    final t = context.t;
    final c = context.colors;
    final next = _next;
    final last = _lastDone;
    final usableCoupons = app.coupons.where((c) => c.usable).length;
    final signedIn = Deps.of(context).session.signedIn;
    final heroes = _banners.where((b) => pickServiceCode(b) == null).toList();
    return Column(
      key: const ValueKey(_HomeView.all),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: c.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Intro(
                  greeting: app.name.isEmpty
                      ? timeGreeting(t, DateTime.now())
                      : t.homeGreeting(app.name),
                  addresses: app.addresses,
                ),
                const SizedBox(height: Space.xs),
                _ServiceGrid(services: app.services),
                const SizedBox(height: Space.md),
                Divider(height: 1, thickness: 1, color: c.line),
                if (_error case final e?) ...[
                  const SizedBox(height: Space.md),
                  _errorCard(e),
                ],
                if (next != null) ...[
                  const SizedBox(height: Space.md),
                  _UpcomingCard(booking: next),
                ],
                if (signedIn &&
                    app.addresses.isEmpty &&
                    app.services.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  _AddAddressCard(),
                ],
                const SizedBox(height: Space.xl),
                FeedSection(
                  cards: _feed,
                  picks: picks,
                  loading: !_loaded,
                  limit: 1,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.xl,
            Space.gutter,
            Space.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (usableCoupons > 0 || heroes.isNotEmpty) ...[
                BannerCarousel(items: heroes, coupons: usableCoupons),
                const SizedBox(height: Space.xl),
              ],
              NewsList(notice: _notice, articles: _articles),
              if (last != null && next == null) ...[
                const SizedBox(height: Space.lg),
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
              const _TrustRow(),
            ],
          ),
        ),
      ],
    );
  }

  /// PICK: every console recommendation and personal card, nothing else.
  Widget _pickView(List<ContentItem> picks) => ColoredBox(
    key: const ValueKey(_HomeView.pick),
    color: context.colors.surface,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.xxxl,
      ),
      child: FeedSection(
        cards: _feed,
        picks: picks,
        loading: !_loaded,
        empty: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xxxl),
          // "Nothing here yet" would be a lie when the feed simply did not load.
          child: _error != null
              ? _errorCard(_error!)
              : Center(
                  child: Text(
                    context.t.noContent,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.inkMuted,
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
}

/// Greeting by local time of day; the name replaces it once the account has one.
String timeGreeting(T t, DateTime now) {
  final h = now.hour;
  if (h < 12) return t.greetMorning;
  if (h < 18) return t.greetAfternoon;
  return t.greetEvening;
}

/// Logo lockup on the left, the all / PICK toggle centred in what is left.
class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.view, required this.onView});
  final _HomeView view;
  final ValueChanged<_HomeView> onView;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      children: [
        // The lockup is an image: it keeps its size at every system text size.
        MediaQuery.withNoTextScaling(
          // Plays once per cold start: the home tab stays mounted behind the others.
          child: const DahaeLogo(
            variant: DahaeLogoVariant.threeD,
            wordmark: true,
            size: _logoSize,
            animate: true,
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _toggleMaxWidth),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: _headerMaxTextScale,
                child: SegmentedControl<_HomeView>(
                  segments: [
                    (_HomeView.all, t.dhHomeAll),
                    (
                      _HomeView.pick,
                      t.dhHomePick(BrandConfig.placeholder.name),
                    ),
                  ],
                  selected: view,
                  onChanged: onView,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One quiet greeting line with the address chip under it (not in the design; kept small).
class _Intro extends StatelessWidget {
  const _Intro({required this.greeting, required this.addresses});
  final String greeting;
  final List<Address> addresses;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // The greeting strings break after the name; here it is one quiet line.
      Text(
        greeting.replaceAll('\n', ' '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodySmall?.copyWith(color: context.colors.inkSoft),
      ),
      _AddressChip(addresses: addresses),
    ],
  );
}

/// Referral needs an account. Tapping asks for sign-in, then shows the real card in place.
class _GuestReferralGate extends StatelessWidget {
  const _GuestReferralGate({required this.onSignedIn});
  final Future<void> Function() onSignedIn;

  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.primaryTint,
    level: Level.flat,
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
    final c = context.colors;
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
            const ExcludeSemantics(child: Icon3D('ui_pin', size: 18)),
            const SizedBox(width: Space.xxs),
            Flexible(
              child: Text(
                label,
                style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 18, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// The next visit as one flat card: when it is, then the same row as on the bookings tab.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final days = DateUtils.dateOnly(
      booking.visitDate,
    ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    return AppCard(
      level: Level.flat,
      border: context.colors.line,
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${t.homeUpcoming} · ${days <= 0 ? t.today : t.dDay('$days')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(
              color: context.colors.inkSoft,
            ),
          ),
          BookingCard(booking: booking, showDate: true),
        ],
      ),
    );
  }
}

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
