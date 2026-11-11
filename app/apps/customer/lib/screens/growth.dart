// Growth widgets: honest social proof, the review sheet with photos, and the referral card.
// Every number comes from the server; a missing or null value hides its line.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui/ui.dart';

import '../state.dart';

const _maxReviewPhotos = 5;

/// Public counters and recent 4-5 star reviews. Renders nothing when there is nothing real to show.
class SocialProofCard extends StatefulWidget {
  const SocialProofCard({super.key});

  @override
  State<SocialProofCard> createState() => _SocialProofCardState();
}

class _SocialProofCardState extends State<SocialProofCard> {
  Json? _proof;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await context.api.get('/public/proof') as Json;
      if (mounted) setState(() => _proof = r);
    } on Object {
      // Decoration only: if the numbers can't load, the card simply stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _proof;
    if (p == null) return const SizedBox.shrink();
    final t = context.t;
    final homes = (p['homes_this_month'] as num?)?.toInt();
    final rating = (p['rating'] as num?)?.toDouble();
    final count = (p['review_count'] as num?)?.toInt();
    final reviews = ((p['reviews'] as List?) ?? const []).cast<Json>();
    if (homes == null && rating == null && reviews.isEmpty) return const SizedBox.shrink();
    return AppCard(
      color: context.colors.tintOf(ServiceHues.of('studio')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (homes != null) Text(t.proofHomes('$homes'), style: context.text.titleSmall),
          if (rating != null && count != null) ...[
            const SizedBox(height: Space.xs),
            Text(t.proofRating(rating.toStringAsFixed(1), '$count'), style: context.text.bodySmall),
          ],
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Text(t.proofReviewsTitle, style: context.text.labelLarge),
            for (final r in reviews)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '★${r['rating']}  ${r['body']}  — ${r['name']}',
                        style: context.text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ReviewReportButton(api: context.api, bookingId: r['booking_id'] as String),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Invite a friend with a copyable code, and enter a friend's code. Hidden while referrals are off.
class ReferralCard extends StatefulWidget {
  const ReferralCard({super.key});

  @override
  State<ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends State<ReferralCard> {
  Json? _info;
  final _claim = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _claim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await context.api.get('/me/referral') as Json;
      if (mounted) setState(() => _info = r);
    } on Object {
      // Optional card: a failed load hides it rather than blocking the home screen.
    }
  }

  Future<void> _claimCode() async {
    final code = _claim.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    final t = context.t;
    try {
      await context.api.post('/me/referral/claim', {'code': code});
      _claim.clear();
      if (mounted) showToast(context, t.referralClaimed);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null || info['enabled'] != true) return const SizedBox.shrink();
    final t = context.t;
    final code = info['code'] as String;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.referralTitle, style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          Text(t.referralBody(context.won((info['amount'] as num).toInt())), style: context.text.bodySmall),
          const SizedBox(height: Space.xs),
          Row(children: [
            Expanded(child: Text(code, style: context.text.titleMedium)),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) showToast(context, t.referralCopied);
              },
              child: Text(t.referralCopy),
            ),
          ]),
          Text(t.referralStats('${info['invited']}', '${info['rewarded']}'), style: context.text.bodySmall),
          const Divider(height: Space.xl),
          Text(t.referralClaimTitle, style: context.text.labelLarge),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _claim,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: t.referralClaimField),
              ),
            ),
            const SizedBox(width: Space.xs),
            FilledButton(onPressed: _busy ? null : _claimCode, child: Text(t.referralClaimButton)),
          ]),
        ],
      ),
    );
  }
}

/// Entry point for a completed booking: opens [ReviewSheet] and reports whether one was saved.
Future<bool?> showReviewSheet(BuildContext context, String bookingId) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(padding: const EdgeInsets.all(Space.gutter), child: ReviewSheet(bookingId: bookingId)),
  ),
);

/// One review per completed booking: 1-5 stars (required), optional text and up to 5 own photos.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 0;
  final _text = TextEditingController();
  final List<String> _photos = [];
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final t = context.t;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final url = await context.api.upload(await file.readAsBytes(), file.name);
      if (mounted) setState(() => _photos.add(url));
    } catch (_) {
      if (mounted) showToast(context, t.reviewPhotoFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final t = context.t;
    try {
      await context.api.post('/bookings/${widget.bookingId}/review', {'rating': _rating, 'body': _text.text.trim(), 'photos': _photos});
      if (!mounted) return;
      // Close first, then confirm on the screen underneath (the sheet's own context is gone after pop).
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(SnackBar(content: Text(t.reviewSaved)));
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.reviewTitle, style: context.text.titleMedium, textAlign: TextAlign.center),
        Text(t.reviewSheetTitle, style: context.text.bodySmall, textAlign: TextAlign.center),
        Text(t.reviewRuleLine, style: context.text.bodySmall, textAlign: TextAlign.center),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              tooltip: t.ratingStars('$i'),
              iconSize: 36,
              onPressed: _busy ? null : () => setState(() => _rating = i),
              icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: context.colors.sun),
            ),
        ]),
        TextField(controller: _text, maxLength: 1000, maxLines: 3, decoration: InputDecoration(hintText: t.reviewHint)),
        const SizedBox(height: Space.xs),
        Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
          for (var i = 0; i < _photos.length; i++) Chip(avatar: const Icon(Icons.image_outlined, size: 18), label: Text('${i + 1}')),
          if (_photos.length < _maxReviewPhotos)
            OutlinedButton.icon(
              onPressed: _busy ? null : _addPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(t.reviewPhotosAdd),
            ),
        ]),
        Text(t.reviewPhotosHint, style: context.text.bodySmall),
        const SizedBox(height: Space.md),
        FilledButton(onPressed: _rating == 0 || _busy ? null : _submit, child: Text(t.reviewSubmit)),
      ],
    );
  }
}
