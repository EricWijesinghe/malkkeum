import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'campaign_tab.dart';
import 'confirm_action.dart';
import 'growth.dart';

// Content can be written in every app language; missing ones fall back to Korean.
final _langs = LocaleController.names.keys.toList();
const _kinds = ['notice', 'news', 'tip', 'faq', 'banner', 'legal'];

String kindLabel(T t, String k) => switch (k) {
  'notice' => t.cKind_notice,
  'news' => t.cKind_news,
  'tip' => t.cKind_tip,
  'faq' => t.cKind_faq,
  'banner' => t.cKind_banner,
  _ => t.cKind_legal,
};

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: t.cIssueCoupon),
              Tab(text: t.cContent),
              Tab(text: t.growthTab),
              Tab(text: t.cmTab),
              Tab(text: t.anFunnel('30')),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _Coupons(),
                _Content(),
                GrowthSettings(),
                CampaignTab(),
                AnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Coupons extends StatefulWidget {
  const _Coupons();
  @override
  State<_Coupons> createState() => _CouponsState();
}

class _CouponsState extends State<_Coupons> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _phones = TextEditingController();
  String? _service;
  bool _all = false;
  bool _busy = false;

  Future<void> _issue() async {
    setState(() => _busy = true);
    final t = context.t;
    try {
      final r = await context.api.post('/admin/coupons', {
        'name': _name.text.trim(),
        'amount': int.parse(_amount.text),
        'service_code': _service,
        'phones': _phones.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'all_customers': _all,
      }) as Json;
      if (mounted) showToast(context, t.cIssued('${r['issued']}'));
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _phones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: t.cCouponName),
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: t.cAmount),
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _service,
                decoration: InputDecoration(labelText: t.cService),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(t.couponAnyService),
                  ),
                  for (final c in const [
                    'studio',
                    'kitchen',
                    'bathroom',
                    'mattress',
                    'aircon',
                    'sofa',
                    'move_out',
                    'move_in',
                  ])
                    DropdownMenuItem(value: c, child: Text(t.service(c))),
                ],
                onChanged: (v) => setState(() => _service = v),
              ),
              const SizedBox(height: Space.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.cAllCustomers),
                value: _all,
                onChanged: (v) => setState(() => _all = v),
              ),
              if (!_all)
                TextField(
                  controller: _phones,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: t.cCouponPhones),
                ),
              const SizedBox(height: Space.md),
              PrimaryButton(
                label: t.cIssueCoupon,
                busy: _busy,
                onPressed: context.console.isAdmin ? _issue : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Content extends StatefulWidget {
  const _Content();
  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();

  Future<void> _edit([Json? item]) async {
    final t = context.t;
    var kind = item?['kind'] as String? ?? 'notice';
    var active = item?['active'] as bool? ?? true;
    final slug = TextEditingController(text: item?['slug'] as String? ?? '');
    // Where a tap goes: an in-app route (`coupons`, `service/<code>` = home recommendation) or https.
    final link = TextEditingController(text: item?['link'] as String? ?? '');
    final titles = {
      for (final l in _langs)
        l: TextEditingController(
          text: ((item?['title'] as Json?)?[l] as String?) ?? '',
        ),
    };
    final bodies = {
      for (final l in _langs)
        l: TextEditingController(
          text:
              (((item?['body'] as Json?)?['text'] as Json?)?[l] as String?) ??
              '',
        ),
    };
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(item == null ? t.cNewContent : t.edit),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: kind,
                          items: [
                            for (final k in _kinds)
                              DropdownMenuItem(
                                value: k,
                                child: Text(kindLabel(t, k)),
                              ),
                          ],
                          onChanged: (v) => set(() => kind = v!),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: TextField(
                          controller: slug,
                          decoration: InputDecoration(
                            labelText: t.cSlug,
                            isDense: true,
                          ),
                        ),
                      ),
                      Switch(
                        value: active,
                        onChanged: (v) => set(() => active = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  TextField(
                    controller: link,
                    decoration: InputDecoration(
                      labelText: t.cLink,
                      isDense: true,
                    ),
                  ),
                  for (final l in _langs) ...[
                    const SizedBox(height: Space.sm),
                    TextField(
                      controller: titles[l],
                      decoration: InputDecoration(
                        labelText: '${t.cTitleField} ($l)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: bodies[l],
                      minLines: 2,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: '${t.cBodyField} ($l)',
                        isDense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
    if (save == true && mounted) {
      final body = {
        'kind': kind,
        'slug': slug.text.trim().isEmpty ? null : slug.text.trim(),
        'title': {
          for (final l in _langs)
            if (titles[l]!.text.isNotEmpty) l: titles[l]!.text,
        },
        'body': {
          'text': {
            for (final l in _langs)
              if (bodies[l]!.text.isNotEmpty) l: bodies[l]!.text,
          },
        },
        'image_url': item?['image_url'],
        'link': link.text.trim().isEmpty ? null : link.text.trim(),
        'sort_order': item?['sort_order'] ?? 0,
        'starts_at': null,
        'ends_at': null,
        'active': active,
      };
      try {
        if (item == null) {
          await context.api.post('/admin/content', body);
        } else {
          await context.api.put('/admin/content/${item['id']}', body);
        }
        if (mounted) showToast(context, t.cSaved);
        await _view.currentState?.reload();
      } catch (e) {
        if (mounted) showToast(context, t.error(e));
      }
    }
    disposeAfterClose([slug, link, ...titles.values, ...bodies.values]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.cNewContent),
      ),
      body: AsyncView<List<Json>>(
        key: _view,
        load: () async =>
            (await context.api.get('/admin/content') as List).cast<Json>(),
        builder: (context, rows, reload) => ListView(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 96),
          children: [
            for (final c in rows)
              Card(
                elevation: 0,
                child: ListTile(
                  leading: Tag(
                    label: kindLabel(t, c['kind'] as String),
                    hue: ServiceHues.of(switch (c['kind']) {
                      'notice' => 'kitchen',
                      'news' => 'aircon',
                      'tip' => 'studio',
                      'faq' => 'mattress',
                      'banner' => 'sofa',
                      _ => 'move_in',
                    }),
                  ),
                  title: Text(
                    ((c['title'] as Json)[context.lang] ??
                            (c['title'] as Json)['ko'] ??
                            '')
                        as String,
                  ),
                  subtitle: Text(
                    [
                      if (c['slug'] != null) c['slug'],
                      if (c['active'] != true) t.statusCancelled,
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    tooltip: t.delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      if (!await confirmAction(context, t.delete) ||
                          !context.mounted) {
                        return;
                      }
                      try {
                        await context.api.delete('/admin/content/${c['id']}');
                        await reload();
                      } catch (e) {
                        if (context.mounted) showToast(context, t.error(e));
                      }
                    },
                  ),
                  onTap: () => _edit(c),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
