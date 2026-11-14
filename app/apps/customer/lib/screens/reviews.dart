import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// One public review: stars as icons, the masked name and the text. Reporting lives in the overflow
/// menu, so the card carries no loud link (store rule: every review stays reportable).
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.api, required this.row});

  final ApiClient api;

  /// A review row from `/public/reviews` or the proof card: rating, body, name, booking_id.
  final Json row;

  Future<void> _report(BuildContext context) async {
    final sent = await showReviewReport(
      context,
      api: api,
      bookingId: row['booking_id'] as String,
    );
    if (sent && context.mounted) showToast(context, context.t.reportThanks);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final rating = (row['rating'] as num?)?.toDouble() ?? 0;
    final name = row['name'] as String? ?? '';
    final body = row['body'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RatingStars(rating: rating, size: 14),
                    const SizedBox(width: Space.xs),
                    Flexible(
                      child: Text(
                        name,
                        style: context.text.labelMedium?.copyWith(
                          color: c.inkMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: Space.xxs),
                  Text(
                    body,
                    style: context.text.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: t.reviewMenu,
            icon: Icon(Icons.more_vert_rounded, color: c.inkMuted),
            onSelected: (_) => _report(context),
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'report',
                child: Text(t.reportAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Every visible review, newest first, a page at a time (pull to refresh, scroll for more).
class ReviewsAllScreen extends StatelessWidget {
  const ReviewsAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: Text(t.reviewsAllTitle)),
      body: PagedView<Json>(
        api: api,
        path: '/public/reviews',
        parse: (r) => r,
        builder: (context, rows, reload) => RefreshIndicator(
          onRefresh: reload,
          child: rows.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Space.xxxl),
                      child: Center(child: Text(t.reviewsEmpty)),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(Space.gutter),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ReviewTile(api: api, row: rows[i]),
                ),
        ),
      ),
    );
  }
}

/// The newest few reviews with 후기 전체 보기. Hidden when there are none or the list cannot load.
class RecentReviews extends StatefulWidget {
  const RecentReviews({super.key});

  @override
  State<RecentReviews> createState() => _RecentReviewsState();
}

class _RecentReviewsState extends State<RecentReviews> {
  static const _shown = 3;
  List<Json> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = (await context.api.get(
        '/public/reviews',
        query: {'limit': '$_shown'},
      ) as List).cast<Json>();
      if (mounted) setState(() => _rows = rows);
    } on Object {
      // Decoration only: without reviews the section simply stays out of PICK.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) return const SizedBox.shrink();
    final t = context.t;
    final api = context.api;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.xl),
        Row(
          children: [
            Expanded(
              child: Text(t.proofReviewsTitle, style: context.text.titleLarge),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReviewsAllScreen(),
                ),
              ),
              child: Text(t.reviewsSeeAll),
            ),
          ],
        ),
        for (final r in _rows) ReviewTile(api: api, row: r),
      ],
    );
  }
}
