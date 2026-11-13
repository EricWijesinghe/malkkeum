import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'service.dart';

const _artSize = 60.0;
const _discSize = 104.0;
const _servicePrefix = 'service/';

/// The glow disc behind the art breathes between these opacities.
const _glowDim = 0.55;
const _glowBright = 0.9;
const _glowPeriod = Duration(milliseconds: 2400);

/// A banner content item whose link is `service/<code>` is a recommended service, not a banner.
String? pickServiceCode(ContentItem item) {
  final link = item.link ?? item.body['link'];
  return link is String && link.startsWith(_servicePrefix)
      ? link.substring(_servicePrefix.length)
      : null;
}

/// Card kinds and reasons come from `domain::feed`; unknown kinds show nothing rather than guess.
String? _cardTitle(T t, String kind) => switch (kind) {
  'resume_quote' => t.feedTitleDraft,
  'next_due' => t.feedTitleDue,
  'rebook_partner' => t.feedTitleRebook,
  'seasonal' => t.feedTitleSeasonal,
  'size_estimate' => t.feedTitleSize,
  'subscription' => t.feedTitleSubscription,
  'district_proof' => t.feedTitleDistrict,
  _ => null,
};

String? _cardWhy(BuildContext context, Json card) {
  final t = context.t;
  final facts = '${card['facts'] ?? 0}';
  return switch (card['reason']) {
    'cadence_due' => t.feedWhyCadence(facts),
    'rated_five' => t.feedWhyRated(facts),
    'draft_unfinished' => t.feedWhyDraft,
    'summer_aircon' => t.feedWhySummer,
    'moving_peak' => t.feedWhyMoving,
    'holiday_deep_clean' => t.feedWhyHoliday(facts),
    'saved_home_size' => t.feedWhySize(facts),
    'repeat_customer' => t.feedWhyRepeat,
    'district_booked' => t.feedWhyDistrict(
      districtByCode(card['district'] as String? ?? '')?.name(context.lang) ??
          '',
      facts,
    ),
    _ => null,
  };
}

/// "Recommended": console picks (banner content linking to a service) first, then the personalized
/// cards from `/feed` (guest) or `/me/feed` (member), each with its "why" line.
class FeedSection extends StatelessWidget {
  const FeedSection({
    super.key,
    required this.cards,
    this.picks = const [],
    this.loading = false,
    this.limit,
    this.empty = const SizedBox.shrink(),
  });
  final List<Json> cards;

  /// Console-written recommendations; one whose service is not in the catalogue is skipped.
  final List<ContentItem> picks;

  /// True before the first answer with nothing cached: shows a skeleton instead of an empty gap.
  final bool loading;

  /// Rows shown (home shows the top one); null shows every pick and card.
  final int? limit;

  /// Shown when there is nothing to recommend.
  final Widget empty;

  List<Widget> _rows(BuildContext context) {
    final app = context.app;
    final t = context.t;
    return [
      for (final p in picks)
        if (app.service(pickServiceCode(p) ?? '') case final service?)
          _RecRow(
            art: 'svc_${service.code}',
            title: p.title(context.lang),
            // The console's own line wins; without one the row names the service and its price.
            body: p.text(context.lang).isNotEmpty
                ? p.text(context.lang)
                : '${t.service(service.code)} · ${service.isQuote ? t.quoteBadge : t.fromPrice(context.won(service.fromPrice ?? 0))}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ServiceScreen(service: service),
              ),
            ),
          ),
      for (final card in cards)
        if (_cardTitle(t, card['kind'] as String? ?? '') case final heading?)
          _RecRow(
            art: card['service'] is String
                ? 'svc_${card['service']}'
                : 'rec_move_combo',
            title: heading,
            body: _cardWhy(context, card),
            onTap: () => openFeedCard(context, card),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty && picks.isEmpty && loading) {
      return const Skeleton(height: _discSize);
    }
    final rows = _rows(context);
    if (rows.isEmpty) return empty;
    final shown = limit == null ? rows : rows.take(limit!).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.t.dhHomeRecommended,
            style: context.text.titleLarge,
          ),
        ),
        const SizedBox(height: Space.xs),
        for (var i = 0; i < shown.length; i++)
          StaggerIn(index: i, child: shown[i]),
      ],
    );
  }
}

/// One recommendation: floating 3D art on a breathing glow, bold title, one supporting line.
class _RecRow extends StatelessWidget {
  const _RecRow({
    required this.art,
    required this.title,
    required this.onTap,
    this.body,
  });
  final String art;
  final String title;
  final String? body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.card),
      onTap: onTap,
      child: Row(
        children: [
          ExcludeSemantics(child: _GlowArt(art: art)),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (body != null && body!.isNotEmpty) ...[
                  const SizedBox(height: Space.xxs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          body!,
                          style: context.text.bodyMedium?.copyWith(
                            color: c.inkSoft,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: c.inkMuted,
                      ),
                    ],
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

/// The art floats over a soft disc that breathes. Still under reduced motion, in a hidden tab
/// (TickerMode) and wherever idle icon motion is switched off.
class _GlowArt extends StatefulWidget {
  const _GlowArt({required this.art});
  final String art;

  @override
  State<_GlowArt> createState() => _GlowArtState();
}

class _GlowArtState extends State<_GlowArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _glowPeriod,
    value: 1,
  );
  late final Animation<double> _glow = Tween(
    begin: _glowDim,
    end: _glowBright,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Icon3D.idleMotion && !MediaQuery.disableAnimationsOf(context)) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = context.colors.primaryTint;
    return SizedBox.square(
      dimension: _discSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _glow,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [tint, tint, tint.withValues(alpha: 0)],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Icon3D(widget.art, size: _artSize, idle: Icon3DIdle.float),
        ],
      ),
    );
  }
}

/// Opens the card's service. A subscription card is an account action, so a guest signs in first
/// and the card then opens as the same tap resumes.
Future<void> openFeedCard(BuildContext context, Json card) async {
  final code = card['service'] as String?;
  final service = code == null ? null : context.appRead.service(code);
  if (service == null) return;
  if (card['kind'] == 'subscription' && !Deps.read(context).session.signedIn) {
    if (!await requireSignIn(context) || !context.mounted) return;
  }
  if (!context.mounted) return;
  final nav = Navigator.of(context);
  await HapticFeedback.selectionClick();
  await nav.push(MaterialPageRoute<void>(builder: (_) => ServiceScreen(service: service)));
}
