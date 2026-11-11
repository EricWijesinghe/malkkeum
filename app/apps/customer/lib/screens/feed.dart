import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'service.dart';

const _cardRadius = 16.0;

/// Personalized cards from `/feed` (guest) or `/me/feed` (member), each with its "why" line.
class FeedSection extends StatelessWidget {
  const FeedSection({super.key, required this.cards, this.loading = false});
  final List<Json> cards;

  /// True before the first answer with nothing cached: shows skeletons instead of an empty gap.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty && loading) {
      return const Column(
        children: [Skeleton(height: 84), SizedBox(height: Space.sm), Skeleton(height: 84)],
      );
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.t.feedHeading),
        ForYouChips(cards: cards),
        const SizedBox(height: Space.sm),
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
    final chips = [
      for (final c in cards)
        if (FeedCardTile.title(t, c['kind'] as String? ?? '') case final String label)
          (label: label, card: c),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: context.text.titleMedium),
              if (reason != null) ...[
                const SizedBox(height: Space.xs),
                Text(reason, style: context.text.bodySmall?.copyWith(color: context.colors.inkSoft)),
              ],
            ],
          ),
        ),
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
  HapticFeedback.selectionClick();
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ServiceScreen(service: service)));
}
