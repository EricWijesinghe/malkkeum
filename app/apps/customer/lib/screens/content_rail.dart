import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'more.dart';

const _thumb = 64.0;
const _thumbRadius = 14.0;
const _thumbArt = 38.0;
const _titleLines = 2;

/// The notice tag never takes more than this share of the screen width.
const _tagMaxShare = 0.3;

const _bannerInterval = Duration(seconds: 5);
const _bannerArt = 84.0;
const _bannerMinHeight = 132.0;
const _bannerCard = Size(104, 68);

/// The coupon art rests tilted and straightens halfway while its page slides (radians: -6° → -3°).
const _artTilt = -0.105;
const _artTiltSliding = -0.052;

/// The art travels this fraction of the page offset, so it lags behind its card.
const _artParallax = 0.3;

/// Rows on home; the heading's "see all" opens the full list.
const newsListMax = 4;

/// Pastel thumbnails for articles that name no service, in the order of the owner design.
const _thumbHues = [
  ServiceHues.studio,
  ServiceHues.aircon,
  ServiceHues.mattress,
  ServiceHues.moveIn,
];

/// "Dahae news": one card with the latest notice on top, then news and tips as article rows.
/// Copy and pictures come from the console; an article whose body names a `service` gets that
/// service as its category and thumbnail. Nothing renders while there is nothing to show.
class NewsList extends StatelessWidget {
  const NewsList({super.key, required this.notice, required this.articles});
  final ContentItem? notice;
  final List<ContentItem> articles;

  @override
  Widget build(BuildContext context) {
    if (notice == null && articles.isEmpty) return const SizedBox.shrink();
    final t = context.t;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(t.dhHomeNews, style: context.text.titleLarge),
              ),
            ),
            // An icon, not a text button: "see all" is long in several languages and the heading
            // must keep its room at large text sizes.
            IconButton(
              tooltip: t.viewAll,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ContentListScreen(kind: 'news', title: t.dhHomeNews),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            side: BorderSide(color: c.isDark ? c.line : Colors.transparent),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                if (notice != null)
                  StaggerIn(index: 0, child: _NoticeRow(item: notice!)),
                for (var i = 0; i < articles.length; i++)
                  StaggerIn(
                    index: i + 1,
                    child: _ArticleRow(item: articles[i], index: i),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

void _open(BuildContext context, ContentItem item) => Navigator.of(context)
    .push(
      MaterialPageRoute<void>(builder: (_) => ContentDetailScreen(item: item)),
    );

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.item});
  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => _open(context, item),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.xs,
          ),
          child: Row(
            children: [
              // A long word at the largest text size trims inside the tag; the title keeps its room.
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * _tagMaxShare,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.inkMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.t.dhNoticeTag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: c.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  item.title(context.lang),
                  style: context.text.bodyMedium?.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (noticeDateLabel(item).isNotEmpty) ...[
                const SizedBox(width: Space.sm),
                Text(
                  noticeDateLabel(item),
                  style: context.text.labelSmall?.copyWith(color: c.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.item, required this.index});
  final ContentItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final code = item.body['service'];
    final service = code is String ? code : null;
    final hue = service == null
        ? _thumbHues[index % _thumbHues.length]
        : ServiceHues.of(service);
    final art = service == null
        ? (item.kind == 'tip' ? 'tip_bulb' : 'news_megaphone')
        : 'svc_$service';
    final fallback = ColoredBox(
      color: c.tintOf(hue),
      child: Center(child: Icon3D(art, size: _thumbArt)),
    );
    final url = item.imageUrl;
    return InkWell(
      onTap: () => _open(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_thumbRadius),
              child: SizedBox.square(
                dimension: _thumb,
                // The picture is decoration; the title beside it carries the meaning.
                child: ExcludeSemantics(
                  child: url == null
                      ? fallback
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          cacheWidth: 192,
                          errorBuilder: (_, _, _) => fallback,
                        ),
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service != null
                        ? t.service(service)
                        : (item.kind == 'tip' ? t.moreTips : t.cKind_news),
                    style: context.text.bodySmall?.copyWith(color: c.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title(context.lang),
                    style: context.text.bodyLarge?.copyWith(color: c.ink),
                    maxLines: _titleLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teal-tint cards that page sideways: the console's banners, or the customer's usable coupons
/// when there is none. Advances by itself unless touched, hidden or under reduced motion.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.items, required this.coupons});
  final List<ContentItem> items;
  final int coupons;

  @override
  State<BannerCarousel> createState() => BannerCarouselState();
}

class BannerCarouselState extends State<BannerCarousel> {
  final _pages = PageController();
  Timer? _timer;
  int _page = 0;
  bool _touching = false;

  int get _count => widget.items.isEmpty ? 1 : widget.items.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= _count) _page = 0;
    _schedule();
  }

  /// TickerMode is off for a tab that is not showing, so a hidden home keeps its page.
  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_count < 2 ||
        _touching ||
        !TickerMode.valuesOf(context).enabled ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _timer = Timer.periodic(_bannerInterval, (_) {
      if (!_pages.hasClients) return;
      _pages.animateToPage(
        (_page + 1) % _count,
        duration: Motion.celebrate,
        curve: Motion.emphasized,
      );
    });
  }

  void _touch(bool down) {
    _touching = down;
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _openBanner(ContentItem? item) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          item == null || (item.link ?? item.body['link']) == 'coupons'
          ? const CouponsScreen()
          : ContentDetailScreen(item: item),
    ),
  );

  /// How far page [i] is from rest, in pages (0 = centred).
  double _offset(int i) =>
      (_pages.hasClients && _pages.position.haveDimensions
          ? _pages.page ?? _page.toDouble()
          : _page.toDouble()) -
      i;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final title = context.text.titleLarge!;
    final sub = context.text.bodySmall!;
    double line(TextStyle s) => (s.fontSize ?? 14) * (s.height ?? 1.4);
    // Two headline lines and a sub-line at the user's font size: large text grows the card.
    final text = MediaQuery.textScalerOf(context)
        .scale(line(title) * 2 + line(sub));
    final height = math.max(_bannerMinHeight, text + Space.lg * 2 + Space.xs);
    final coupons = widget.coupons > 0
        ? t.couponAvailable('${widget.coupons}')
        : null;
    return Listener(
      onPointerDown: (_) => _touch(true),
      onPointerUp: (_) => _touch(false),
      onPointerCancel: (_) => _touch(false),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            PageView.builder(
              key: const ValueKey('home-banners'),
              controller: _pages,
              itemCount: _count,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, i) {
                final item = widget.items.elementAtOrNull(i);
                final body = item?.text(context.lang) ?? '';
                final cardValue = item?.cardValue(context.lang) ?? '';
                return _BannerPage(
                  title: item?.title(context.lang) ?? t.moreCoupons,
                  body: body.isNotEmpty ? body : coupons,
                  onTap: () => _openBanner(item),
                  art: AnimatedBuilder(
                    animation: _pages,
                    builder: (context, child) {
                      final d = _offset(i);
                      final slide = d.abs().clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(
                          d * _artParallax * MediaQuery.sizeOf(context).width,
                          0,
                        ),
                        child: Transform.rotate(
                          angle:
                              _artTilt + (_artTiltSliding - _artTilt) * slide,
                          child: child,
                        ),
                      );
                    },
                    // Console content with a `card` draws it; any other banner keeps the coupon art.
                    child: cardValue.isEmpty
                        ? const Icon3D(
                            'banner_coupon',
                            size: _bannerArt,
                            idle: Icon3DIdle.sway,
                          )
                        : _BannerCard(
                            label: item!.cardLabel(context.lang),
                            value: cardValue,
                          ),
                  ),
                );
              },
            ),
            if (_count > 1)
              PositionedDirectional(
                end: Space.sm,
                bottom: Space.sm,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    // The page number rolls as the carousel turns.
                    child: AmountSwitcher(
                      value: _page + 1,
                      format: (n) => t.dhBannerPage('$n', '$_count'),
                      style: context.text.labelMedium?.copyWith(
                        color: c.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A banner's art card (design p01): a small label over a big value, on the brand colour.
class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: _bannerCard.width,
      height: _bannerCard.height,
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: context.primary,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      // Art, not copy: the card keeps its size and shrinks long or large text to fit.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty)
              Text(label, style: context.text.labelSmall?.copyWith(color: on)),
            Text(
              value,
              style: context.text.titleLarge?.copyWith(
                color: on,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPage extends StatelessWidget {
  const _BannerPage({
    required this.title,
    required this.body,
    required this.onTap,
    required this.art,
  });
  final String title;
  final String? body;
  final VoidCallback onTap;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primaryTint,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleLarge?.copyWith(color: c.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (body != null) ...[
                      const SizedBox(height: Space.xs),
                      Text(
                        body!,
                        style: context.text.bodySmall?.copyWith(
                          color: c.inkSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              ExcludeSemantics(child: RepaintBoundary(child: art)),
            ],
          ),
        ),
      ),
    );
  }
}
