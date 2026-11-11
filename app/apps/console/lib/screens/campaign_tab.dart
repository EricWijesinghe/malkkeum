import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'analytics_view.dart';
import 'campaigns.dart';

/// Marketing tab: the campaign builder, then the send log of past campaigns.
class CampaignTab extends StatelessWidget {
  const CampaignTab({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    return Column(
      children: [
        Expanded(
          child: CampaignBuilder(
            preview: (audience) async => await api.post('/admin/campaigns/preview', {'audience': audience}) as Json,
            submit: (body, at) async {
              final c = await api.post('/admin/campaigns', body) as Json;
              await api.post('/admin/campaigns/${c['id']}/schedule', {'at': at?.toIso8601String()});
            },
            testSend: (phone, body, optout) async {
              await api.post('/admin/campaigns/test', {'phone': phone, 'body': body, 'optout_number': optout});
            },
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 180, child: CampaignLog()),
      ],
    );
  }
}

/// Recent campaigns; tapping one shows its send counts (sent, no consent, failed).
class CampaignLog extends StatelessWidget {
  const CampaignLog({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    final t = context.t;
    return FutureBuilder<List<dynamic>>(
      future: api.get('/admin/campaigns').then((v) => v as List<dynamic>),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(t.error(snap.error!)));
        final rows = snap.data;
        if (rows == null) return const Center(child: CircularProgressIndicator());
        return ListView(
          children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(t.cmLog, style: Theme.of(context).textTheme.titleMedium)),
            for (final c in rows.cast<Json>())
              ListTile(
                dense: true,
                title: Text('${c['name']}'),
                subtitle: Text('${c['channel']} · ${c['status']}'),
                onTap: () async {
                  final d = await api.get('/admin/campaigns/${c['id']}') as Json;
                  final s = (d['stats'] as Map?) ?? const {};
                  if (context.mounted) {
                    showToast(context, '${t.cmStatSent('${s['sent'] ?? 0}')} · ${t.cmStatSkipped('${s['skipped_consent'] ?? 0}')} · ${t.cmStatFailed('${s['failed'] ?? 0}')}');
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

/// Analytics tab: funnel and cohorts over the server's windows.
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    return AnalyticsView(
      funnel: (days) async => await api.get('/admin/analytics/funnel', query: {'days': '$days'}) as Json,
      cohorts: (weeks) async => (await api.get('/admin/analytics/cohorts', query: {'weeks': '$weeks'}) as List<dynamic>).cast<Json>(),
    );
  }
}
