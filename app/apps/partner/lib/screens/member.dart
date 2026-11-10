import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'complete.dart';

/// How far back and ahead a team member sees their jobs (server allows up to 62 days).
const _pastDays = 7;
const _aheadDays = 45;

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Team-member login: only the jobs the team lead assigned, with address and notes; completion
/// with photos. No feed, quotes or payouts (the server hides them from members too).
class MemberShell extends StatelessWidget {
  const MemberShell({super.key});

  Future<(Json, List<Booking>)> _load(ApiClient api) async {
    final now = DateTime.now();
    final results = await Future.wait([
      api.get('/member/me'),
      api.get(
        '/member/jobs',
        query: {
          'from': _iso(now.subtract(const Duration(days: _pastDays))),
          'to': _iso(now.add(const Duration(days: _aheadDays))),
        },
      ),
    ]);
    return (
      results[0] as Json,
      (results[1] as List).map((e) => Booking.fromJson(e as Json)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final deps = Deps.of(context);
    return Scaffold(
      body: AsyncView<(Json, List<Booking>)>(
        load: () => _load(deps.app.api),
        builder: (context, data, reload) {
          final (me, jobs) = data;
          final upcoming = jobs
              .where((b) => b.status < 3 && b.status >= 0)
              .toList();
          final done = jobs.where((b) => b.status == 3).toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(t.mMyJobs),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (v) =>
                          v == 'logout' ? deps.session.logout() : null,
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'logout', child: Text(t.logout)),
                      ],
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.gutter,
                    ),
                    child: Text(
                      t.mTeam(me['team_name'] as String? ?? ''),
                      style: context.text.titleMedium?.copyWith(
                        color: context.colors.inkSoft,
                      ),
                    ),
                  ),
                ),
                if (jobs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.event_available_rounded,
                      title: t.mMyJobs,
                      body: t.mNoJobs,
                      hue: ServiceHues.studio,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(Space.gutter),
                    sliver: SliverList.list(
                      children: [
                        for (final (i, b) in [...upcoming, ...done].indexed)
                          StaggerIn(
                            index: i,
                            child: _JobCard(booking: b, onChanged: reload),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.booking, required this.onChanged});
  final Booking booking;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = booking;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => MemberJobScreen(id: b.id)),
          );
          await onChanged();
        },
        child: Row(
          children: [
            ServiceGlyph(b.serviceCode, size: 48),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.service(b.serviceCode),
                    style: context.text.titleMedium,
                  ),
                  Text(
                    '${dateLabel(b.visitDate, context.lang)} · ${b.startHour}:00',
                    style: context.text.bodyMedium,
                  ),
                  Text(
                    '${b.address['road_address'] ?? ''}',
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            StatusBadge(status: b.status, label: t.status(b.status)),
          ],
        ),
      ),
    );
  }
}

class MemberJobScreen extends StatelessWidget {
  const MemberJobScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<Json>(
        load: () async => await context.api.get('/member/jobs/$id') as Json,
        builder: (context, data, reload) {
          final b = Booking.fromJson(data['booking'] as Json);
          final notes = b.visitNotes.values
              .where((v) => v is String && v.isNotEmpty)
              .cast<String>()
              .toList();
          final memo = data['team_memo'] as String?;
          return ListView(
            padding: const EdgeInsets.all(Space.gutter),
            children: [
              Row(
                children: [
                  ServiceGlyph(b.serviceCode, size: 56),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      t.service(b.serviceCode),
                      style: context.text.headlineSmall,
                    ),
                  ),
                  StatusBadge(status: b.status, label: t.status(b.status)),
                ],
              ),
              const SizedBox(height: Space.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(
                      icon: Icons.event_rounded,
                      text:
                          '${dateLabel(b.visitDate, context.lang)} · ${b.startHour}:00',
                    ),
                    _Line(
                      icon: Icons.place_rounded,
                      text:
                          '${b.address['road_address'] ?? ''} ${b.address['detail'] ?? ''}',
                    ),
                    _Line(
                      icon: Icons.person_rounded,
                      text: '${t.pCustomer} ${data['customer_name'] ?? ''}',
                    ),
                  ],
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                SectionTitle(t.pCustomerRequests),
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: Text('• $n'),
                  ),
              ],
              if (memo != null && memo.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                SectionTitle(t.pTeamMemo),
                Text(memo),
              ],
              const SizedBox(height: Space.xl),
              if (b.status == 2)
                PrimaryButton(
                  label: t.pComplete,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CompleteScreen(
                          bookingId: b.id,
                          isQuote: b.isQuote,
                          basePath: '/member',
                        ),
                      ),
                    );
                    await reload();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.primary),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: context.text.bodyLarge)),
      ],
    ),
  );
}
