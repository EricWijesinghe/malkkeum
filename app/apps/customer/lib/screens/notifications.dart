import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_detail.dart';
import 'more.dart';

/// Unread alert count for the home bell. Network trouble just hides the dot.
Future<int> unreadAlerts(ApiClient api) async {
  try {
    final rows = (await api.get('/me/notifications') as List).cast<Json>();
    return rows.where((r) => r['read_at'] == null).length;
  } catch (_) {
    return 0;
  }
}

/// Bell destination: personal alerts (booking updates, chat, quotes) and the public notices.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.nAlerts),
          bottom: TabBar(
            tabs: [
              Tab(text: t.nAlerts),
              Tab(text: t.moreNotices),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _Alerts(),
            ContentListBody(kind: 'notice'),
          ],
        ),
      ),
    );
  }
}

class _Alerts extends StatefulWidget {
  const _Alerts();
  @override
  State<_Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<_Alerts> {
  Future<List<Json>> _load() async {
    final api = context.api;
    final rows = (await api.get('/me/notifications') as List).cast<Json>();
    // Opening the inbox reads everything; the list still shows which ones were new.
    if (rows.any((r) => r['read_at'] == null)) {
      api.post('/me/notifications/read').ignore();
    }
    return rows;
  }

  IconData _icon(String kind) => switch (kind) {
    'chat.message' => Icons.forum_rounded,
    'booking.cancelled' => Icons.event_busy_rounded,
    final String k when k.startsWith('quote') => Icons.request_quote_rounded,
    final String k when k.startsWith('booking') =>
      Icons.event_available_rounded,
    _ => Icons.notifications_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<List<Json>>(
      load: _load,
      builder: (context, rows, reload) => rows.isEmpty
          ? EmptyState(icon: Icons.notifications_off_rounded, title: t.nEmpty)
          : RefreshIndicator(
              onRefresh: reload,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _AlertTile(
                  row: rows[i],
                  icon: _icon(rows[i]['kind'] as String? ?? ''),
                ),
              ),
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.row, required this.icon});
  final Json row;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final data = (row['data'] as Json?) ?? const {};
    final unread = row['read_at'] == null;
    final at = DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal();
    final bookingId = (data['data'] as Json?)?['booking_id'] as String?;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: context.colors.primaryTint,
            child: Icon(icon, color: context.primary),
          ),
          if (unread)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.colors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        data['title'] as String? ?? '',
        style: unread ? context.text.titleSmall : context.text.bodyLarge,
      ),
      subtitle: Text(
        [
          if ((data['body'] as String?)?.isNotEmpty ?? false)
            data['body'] as String,
          if (at != null) DateFormat.MMMd(context.lang).add_Hm().format(at),
        ].join('\n'),
      ),
      isThreeLine: (data['body'] as String?)?.isNotEmpty ?? false,
      onTap: bookingId == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BookingDetailScreen(id: bookingId),
              ),
            ),
    );
  }
}
