import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import 'more.dart';

/// Bookings tab for a guest: a static sample of how a booking goes, and one way to start a quote.
/// Nothing here reads account data, so no sign-in is asked until the guest acts.
class GuestBookingsTab extends StatelessWidget {
  const GuestBookingsTab({super.key, required this.onOpenTab});

  /// Opens a tab by index; tab 0 is home, which holds the service grid.
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final steps = [
      (t.guestFlowQuote, t.guestFlowQuoteBody),
      (t.guestFlowConfirm, t.guestFlowConfirmBody),
      (t.guestFlowVisit, t.guestFlowVisitBody),
      (t.guestFlowDone, t.guestFlowDoneBody),
    ];
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        Text(t.guestFlowTitle, style: context.text.titleMedium),
        const SizedBox(height: Space.md),
        for (var i = 0; i < steps.length; i++)
          _FlowStep(index: i + 1, title: steps[i].$1, body: steps[i].$2),
        const SizedBox(height: Space.sm),
        PrimaryButton(
          label: t.guestFirstQuoteCta,
          onPressed: () => onOpenTab(0),
        ),
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.index, required this.title, required this.body});
  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: c.primaryTint,
            child: Text('$index', style: context.text.labelLarge),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(
                  body,
                  style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat tab for a guest: the owner's FAQ and terms, then one sign-in button for talking to a person.
class GuestChatTab extends StatelessWidget {
  const GuestChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.gutter),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.gutter,
            Space.gutter,
            Space.sm,
          ),
          child: Text(t.guestFaqTitle, style: context.text.titleMedium),
        ),
        AsyncView<List<ContentItem>>(
          load: () async =>
              (await context.api.get('/content', query: {'kind': 'faq'}) as List)
                  .map((e) => ContentItem(e as Json))
                  .toList(),
          builder: (context, items, _) => Column(
            children: [for (final f in items) FaqRow(item: f)],
          ),
        ),
        const SizedBox(height: Space.md),
        ListTile(
          title: Text(t.moreTerms),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openLegal(context, 'terms', t.moreTerms),
        ),
        ListTile(
          title: Text(t.morePrivacy),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openLegal(context, 'privacy', t.morePrivacy),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: PrimaryButton(
            label: t.guestChatCta,
            onPressed: () => requireSignIn(context, reason: SignInReason.chat),
          ),
        ),
      ],
    );
  }

  void _openLegal(BuildContext context, String slug, String title) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LegalScreen(slug: slug, title: title),
        ),
      );
}
