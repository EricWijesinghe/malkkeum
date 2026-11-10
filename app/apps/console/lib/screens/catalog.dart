import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Prices, durations, availability, slot capacity and the quote formula — no code change needed.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [Tab(text: t.cPricing), Tab(text: t.cSlotCapacity), Tab(text: t.cFormula)]),
        const Expanded(child: TabBarView(children: [_Services(), _Capacity(), _Formula()])),
      ]),
    );
  }
}

Widget _num(TextEditingController c, String label) => TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, isDense: true),
    );

class _Services extends StatefulWidget {
  const _Services();
  @override
  State<_Services> createState() => _ServicesState();
}

class _ServicesState extends State<_Services> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();

  Future<void> _edit(Json s) async {
    final t = context.t;
    final pricing = Map<String, dynamic>.from(s['pricing'] as Json);
    final type = pricing['type'] as String;
    final ctrls = <String, TextEditingController>{};
    TextEditingController c(String k, Object? v) => ctrls.putIfAbsent(k, () => TextEditingController(text: '${v ?? ''}'));
    final units = ((pricing['units'] as List?) ?? const []).cast<Json>();
    var active = s['active'] as bool;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(t.service(s['code'] as String)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.cActive), value: active, onChanged: (v) => set(() => active = v)),
                if (type == 'fixed') ...[_num(c('price', pricing['price']), t.listPrice), const SizedBox(height: 8), _num(c('minutes', pricing['minutes']), t.cMinutes)],
                if (type == 'unit')
                  for (var i = 0; i < units.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        SizedBox(width: 120, child: Text(t.unit(units[i]['label_key'] as String))),
                        Expanded(child: _num(c('p$i', units[i]['price']), t.listPrice)),
                        const SizedBox(width: 8),
                        Expanded(child: _num(c('m$i', units[i]['minutes']), t.cMinutes)),
                      ]),
                    ),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.save))],
        ),
      ),
    );
    if (ok == true && mounted) {
      int v(String k) => int.tryParse(ctrls[k]?.text ?? '') ?? 0;
      final next = switch (type) {
        'fixed' => {'type': 'fixed', 'price': v('price'), 'minutes': v('minutes')},
        'unit' => {'type': 'unit', 'units': [for (var i = 0; i < units.length; i++) {'label_key': units[i]['label_key'], 'price': v('p$i'), 'minutes': v('m$i')}]},
        _ => {'type': 'quote'},
      };
      try {
        await context.api.put('/admin/services/${s['code']}', {
          'pricing': next,
          'needs_preparation': s['needs_preparation'],
          'max_pyeong': s['max_pyeong'],
          'content': s['content'],
          'active': active,
          'sort_order': s['sort_order'],
        });
        if (mounted) showToast(context, t.cSaved);
        await _view.currentState?.reload();
      } catch (e) {
        if (mounted) showToast(context, t.error(e));
      }
    }
    disposeAfterClose(ctrls.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<List<Json>>(
      key: _view,
      load: () async => (await context.api.get('/admin/services') as List).cast<Json>(),
      builder: (context, rows, _) => ListView(padding: const EdgeInsets.all(Space.lg), children: [
        for (final s in rows)
          Card(
            elevation: 0,
            child: ListTile(
              leading: ServiceGlyph(s['code'] as String, size: 40),
              title: Text(t.service(s['code'] as String)),
              subtitle: Text(_priceSummary(context, s['pricing'] as Json)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (s['active'] != true) Tag(label: t.statusCancelled, hue: StatusHues.cancelled),
                const Icon(Icons.edit_outlined),
              ]),
              onTap: context.console.isAdmin ? () => _edit(s) : () => showToast(context, t.cAdminOnly),
            ),
          ),
      ]),
    );
  }

  String _priceSummary(BuildContext context, Json p) => switch (p['type']) {
        'fixed' => '${context.won((p['price'] as num).toInt())} · ${context.t.duration((p['minutes'] as num).toInt())}',
        'unit' => (p['units'] as List).cast<Json>().map((u) => context.won((u['price'] as num).toInt())).join(' / '),
        _ => context.t.quoteBadge,
      };
}

class _Capacity extends StatefulWidget {
  const _Capacity();
  @override
  State<_Capacity> createState() => _CapacityState();
}

class _CapacityState extends State<_Capacity> {
  final _ctrls = <int, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<List<List<dynamic>>>(
      load: () async => (await context.api.get('/admin/slot-capacity') as List).cast<List<dynamic>>(),
      builder: (context, rows, reload) {
        for (final r in rows) {
          _ctrls.putIfAbsent((r[0] as num).toInt(), () => TextEditingController(text: r[1] == null ? '' : '${r[1]}'));
        }
        return ListView(padding: const EdgeInsets.all(Space.lg), children: [
          for (final e in _ctrls.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(children: [
                SizedBox(width: 120, child: Text(hourLabel(e.key, context.lang), style: context.text.titleSmall)),
                Expanded(child: TextField(controller: e.value, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(hintText: t.cUnlimited, isDense: true))),
              ]),
            ),
          FilledButton(
            onPressed: () async {
              try {
                await context.api.put('/admin/slot-capacity', [for (final e in _ctrls.entries) [e.key, int.tryParse(e.value.text)]]);
                if (context.mounted) showToast(context, t.cSaved);
              } catch (err) {
                if (context.mounted) showToast(context, t.error(err));
              }
            },
            child: Text(t.save),
          ),
        ]);
      },
    );
  }
}

class _Formula extends StatefulWidget {
  const _Formula();
  @override
  State<_Formula> createState() => _FormulaState();
}

class _FormulaState extends State<_Formula> {
  static const _keys = ['base_studio', 'base_one_and_half', 'base_two_rooms', 'base_three_rooms', 'base_four_plus', 'per_extra_bathroom', 'per_balcony', 'duplex', 'no_elevator_high_floor'];
  final _ctrls = <String, TextEditingController>{};
  Json _formula = const {};

  String _label(T t, String k) => switch (k) {
        'base_studio' => t.f_base_studio,
        'base_one_and_half' => t.f_base_one_and_half,
        'base_two_rooms' => t.f_base_two_rooms,
        'base_three_rooms' => t.f_base_three_rooms,
        'base_four_plus' => t.f_base_four_plus,
        'per_extra_bathroom' => t.f_per_extra_bathroom,
        'per_balcony' => t.f_per_balcony,
        'duplex' => t.f_duplex,
        _ => t.f_no_elevator_high_floor,
      };

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      load: () async => await context.api.get('/admin/quote-formula') as Json,
      builder: (context, f, _) {
        _formula = f;
        for (final k in _keys) {
          _ctrls.putIfAbsent(k, () => TextEditingController(text: '${f[k]}'));
        }
        return ListView(padding: const EdgeInsets.all(Space.lg), children: [
          for (final k in _keys) Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: _num(_ctrls[k]!, _label(t, k))),
          Text('${t.cSurcharge} ${f['type_bps']} · ${t.luggageTitle} ${f['luggage_bps']} · VAT ${(f['vat_bps'] as num) / 100}% · ${t.deposit} ${(f['deposit_bps'] as num) / 100}%', style: context.text.bodySmall),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: !context.console.isAdmin
                ? null
                : () async {
                    try {
                      await context.api.put('/admin/quote-formula', {..._formula, for (final k in _keys) k: int.tryParse(_ctrls[k]!.text) ?? _formula[k]});
                      if (context.mounted) showToast(context, t.cSaved);
                    } catch (e) {
                      if (context.mounted) showToast(context, t.error(e));
                    }
                  },
            child: Text(t.save),
          ),
        ]);
      },
    );
  }
}
