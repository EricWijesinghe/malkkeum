// Marketing > growth: welcome offer and referral settings, plus review moderation.
// Settings are saved as a whole; the server validates ranges and writes an audit row.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'acquisition.dart';
import 'cases.dart';
import 'review_reports.dart';

class GrowthSettings extends StatefulWidget {
  const GrowthSettings({super.key});

  @override
  State<GrowthSettings> createState() => _GrowthSettingsState();
}

class _GrowthSettingsState extends State<GrowthSettings> {
  Json? _welcome;
  Json? _referral;
  List<Json> _reviews = const [];
  bool _loading = true;
  final _welcomeValue = TextEditingController();
  final _referralAmount = TextEditingController();
  String _kind = 'amount';
  bool _welcomeOn = false;
  bool _referralOn = false;

  @override
  void initState() {
    super.initState();
    // _load reads context (api, t); after the first frame the inherited widgets are reachable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _welcomeValue.dispose();
    _referralAmount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.api;
    final t = context.t;
    try {
      final results = await Future.wait([api.get('/admin/growth'), api.get('/admin/reviews')]);
      if (!mounted) return;
      final overview = results[0] as Json;
      final welcome = overview['welcome'] as Json;
      final referral = overview['referral'] as Json;
      setState(() {
        _welcome = welcome;
        _referral = referral;
        _welcomeOn = welcome['enabled'] == true;
        _kind = welcome['kind'] as String? ?? 'amount';
        _welcomeValue.text = '${welcome['value']}';
        _referralOn = referral['enabled'] == true;
        _referralAmount.text = '${referral['amount']}';
        _reviews = (results[1] as List).cast<Json>();
      });
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveWelcome() async {
    final t = context.t;
    try {
      await context.api.put('/admin/growth/welcome', {
        'enabled': _welcomeOn,
        'kind': _kind,
        'value': int.parse(_welcomeValue.text),
      });
      if (mounted) showToast(context, t.offerSaved);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  Future<void> _saveReferral() async {
    final t = context.t;
    try {
      await context.api.put('/admin/growth/referral', {
        'enabled': _referralOn,
        'amount': int.parse(_referralAmount.text),
      });
      if (mounted) showToast(context, t.offerSaved);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  Future<void> _moderate(Json review) async {
    final t = context.t;
    final hide = review['hidden'] != true;
    try {
      await context.api.put('/admin/reviews/${review['booking_id']}', {'hidden': hide});
      await _load();
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        const AcquisitionTable(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_welcome != null) ...[
                Text(t.welcomeOfferTitle, style: context.text.titleMedium),
                Text(t.welcomeOfferBody, style: context.text.bodySmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.offerEnabled),
                  value: _welcomeOn,
                  onChanged: (v) => setState(() => _welcomeOn = v),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _kind,
                  decoration: const InputDecoration(),
                  items: [
                    DropdownMenuItem(value: 'amount', child: Text(t.offerKindAmount)),
                    DropdownMenuItem(value: 'percent', child: Text(t.offerKindPercent)),
                  ],
                  onChanged: (v) => setState(() => _kind = v ?? 'amount'),
                ),
                const SizedBox(height: Space.sm),
                TextField(
                  controller: _welcomeValue,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: t.offerValue),
                ),
                const SizedBox(height: Space.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: _saveWelcome, child: Text(t.save)),
                ),
                const Divider(height: Space.xxl),
              ],
              if (_referral != null) ...[
                Text(t.referralSettingsTitle, style: context.text.titleMedium),
                Text(t.referralSettingsBody, style: context.text.bodySmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.offerEnabled),
                  value: _referralOn,
                  onChanged: (v) => setState(() => _referralOn = v),
                ),
                TextField(
                  controller: _referralAmount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: t.referralRewardAmount),
                ),
                const SizedBox(height: Space.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: _saveReferral, child: Text(t.save)),
                ),
                const Divider(height: Space.xxl),
              ],
              ReviewReportQueue(
                fetch: () async => (await context.api.get('/admin/reviews/reports') as List).cast<Json>(),
                decide: (id, action) async => context.api.put('/admin/reviews/$id/decision', {'action': action}),
                setAuthorBlocked: (id, blocked) async => context.api.put('/admin/reviews/$id/author', {'blocked': blocked}),
              ),
              const Divider(height: Space.xxl),
              CaseQueue(
                fetch: () async => (await context.api.get('/admin/cases') as List).cast<Json>(),
                detail: (id) async => await context.api.get('/admin/cases/$id') as Json,
                update: (id, body) async => await context.api.put('/admin/cases/$id', body) as Json,
                reassign: (id, body) async => await context.api.post('/admin/cases/$id/reassign', body) as Json,
                isAdmin: context.console.isAdmin,
              ),
              const Divider(height: Space.xxl),
              Text(t.reviewsModerationTitle, style: context.text.titleMedium),
              const SizedBox(height: Space.sm),
              if (_reviews.isEmpty) Text(t.growthReviewCount('0'), style: context.text.bodySmall),
              for (final r in _reviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('★${r['rating']}', style: context.text.titleSmall),
                          const SizedBox(width: Space.xs),
                          Expanded(child: Text('${r['number']} · ${r['customer_name']}', style: context.text.bodySmall)),
                          if (r['hidden'] == true) Chip(label: Text(t.reviewHiddenTag)),
                        ]),
                        if ((r['body'] as String).isNotEmpty) Text(r['body'] as String, style: context.text.bodyMedium),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _moderate(r),
                            child: Text(r['hidden'] == true ? t.reviewShow : t.reviewHide),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
