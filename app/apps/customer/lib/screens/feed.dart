import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'service.dart';

const _cardRadius = 16.0;

const _artSize = 48.0;
const _servicePrefix = 'service/';

/// A banner content item whose link is `service/<code>` is a recommended service, not the hero banner.
String? pickServiceCode(ContentItem item) {
  final link = item.link ?? item.body['link'];
  return link is String && link.startsWith(_servicePrefix)
      ? link.substring(_servicePrefix.length)
      : null;
}

/// "Recommended": console picks (banner content linking to a service) first, then the personalized
/// cards from `/feed` (guest) or `/me/feed` (member), each with its "why" line.
class FeedSection extends StatelessWidget {
  const FeedSection({
    super.key,
    required this.cards,
    this.picks = const [],
    this.loading = false,
  });
  final List<Json> cards;

  /// Console-written recommendations; one whose service is not in the catalogue is skipped.
  final List<ContentItem> picks;

  /// True before the first answer with nothing cached: shows skeletons instead of an empty gap.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty && loading) {
      return const Column(
        children: [Skeleton(height: 84), SizedBox(height: Space.sm), Skeleton(height: 84)],
      );
    }
    final app = context.app;
    final shown = [
      for (final p in picks)
        if (app.service(pickServiceCode(p) ?? '') != null) p,
    ];
    if (cards.isEmpty && shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.t.dhHomeRecommended),
        for (final p in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: _PickCard(item: p, service: app.service(pickServiceCode(p)!)!),
          ),
        ForYouChips(cards: cards),
        if (cards.isNotEmpty) const SizedBox(height: Space.sm),
        for (var i = 0; i < cards.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: EnterMotion(
              delay: Duration(milliseconds: 60 * i),
              child: FeedCardTile(card: cards[i]),
            ),
          ),
      ],
    );
  }
}

/// Horizontal quick-jump chips over the same cards, so the best matches are one tap away.
class ForYouChips extends StatelessWidget {
  const ForYouChips({super.key, required this.cards});
  final List<Json> cards;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // Short service names, not the card headings, so chips never repeat a heading verbatim.
    final chips = [
      for (final c in cards)
        if (c['service'] is String) (label: t.serviceShort(c['service'] as String), card: c),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
        itemBuilder: (_, i) => ActionChip(
          label: Text(chips[i].label),
          onPressed: () => openFeedCard(context, chips[i].card),
        ),
      ),
    );
  }
}

class FeedCardTile extends StatelessWidget {
  const FeedCardTile({super.key, required this.card});
  final Json card;

  /// Card kinds and reasons come from `domain::feed`; unknown kinds show nothing rather than guess.
  static String? title(T t, String kind) => switch (kind) {
    'resume_quote' => t.feedTitleDraft,
    'next_due' => t.feedTitleDue,
    'rebook_partner' => t.feedTitleRebook,
    'seasonal' => t.feedTitleSeasonal,
    'size_estimate' => t.feedTitleSize,
    'subscription' => t.feedTitleSubscription,
    'district_proof' => t.feedTitleDistrict,
    _ => null,
  };

  static String? why(BuildContext context, Json card) {
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
        districtByCode(card['district'] as String? ?? '')?.name(context.lang) ?? '',
        facts,
      ),
      _ => null,
    };
  }


  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final kind = card['kind'] as String? ?? '';
    final heading = title(t, kind);
    if (heading == null) return const SizedBox.shrink();
    final reason = why(context, card);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(_cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openFeedCard(context, card),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: _ArtRow(
            art: card['service'] is String ? 'svc_${card['service']}' : null,
            title: heading,
            body: reason,
          ),
        ),
      ),
    );
  }
}

/// 3D art on the left, heading and one supporting line on the right.
class _ArtRow extends StatelessWidget {
  const _ArtRow({required this.art, required this.title, this.body});
  final String? art;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (art != null) ...[
        ExcludeSemantics(child: Icon3D(art!, size: _artSize)),
        const SizedBox(width: Space.md),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleMedium),
            if (body != null && body!.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Text(
                body!,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

/// A console-written recommendation (e.g. "move-in cleaning incl. pre-move-out"): opens its service.
class _PickCard extends StatelessWidget {
  const _PickCard({required this.item, required this.service});
  final ContentItem item;
  final Service service;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(Space.md),
    color: context.colors.primaryTint,
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ServiceScreen(service: service)),
    ),
    child: _ArtRow(
      art: service.isQuote ? 'rec_move_combo' : 'svc_${service.code}',
      title: item.title(context.lang),
      body: item.text(context.lang),
    ),
  );
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
