import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

/// Counted pricing ("수량 선택"): the owner sets options, a per-option cap and a multi-item discount.
/// The math mirrors the server rule (CR-7.1): a basket of two or more items gets the discount,
/// and minutes never fall below one hour.
const countsMinMinutes = 60;
const countsMaxEachCap = 20;
const countsMaxDiscountPct = 50;

/// One option row as the owner sees it: label, price in won, minutes.
class CountOption {
  const CountOption({
    required this.label,
    required this.minutes,
    required this.price,
  });

  final String label;
  final int minutes;
  final int price;
}

/// Preview result for one basket. [off] is the discount in won.
class CountQuote {
  const CountQuote({
    required this.won,
    required this.minutes,
    required this.off,
  });

  final int won;
  final int minutes;
  final int off;
}

/// Price and duration for [counts] (one entry per option, same order). Empty basket costs nothing.
CountQuote countQuote(
  List<CountOption> options,
  List<int> counts,
  int discountBps,
) {
  var total = 0, minutes = 0, items = 0;
  for (var i = 0; i < options.length; i++) {
    final n = counts[i];
    total += options[i].price * n;
    minutes += options[i].minutes * n;
    items += n;
  }
  if (items == 0) return const CountQuote(won: 0, minutes: 0, off: 0);
  final off = items >= 2 ? _roundTo100(total * discountBps ~/ 10000) : 0;
  return CountQuote(
    won: total - off,
    minutes: minutes < countsMinMinutes ? countsMinMinutes : minutes,
    off: off,
  );
}

int _roundTo100(int won) => (won + 50) ~/ 100 * 100;

/// Swaps two list entries in place (used by the reorder buttons).
void swapAt<E>(List<E> xs, int i, int j) {
  final first = xs[i];
  xs[i] = xs[j];
  xs[j] = first;
}

/// Options as stored in a `counts` pricing JSON.
List<CountOption> countOptionsOf(Json pricing) => [
  for (final u in ((pricing['units'] as List?) ?? const []).cast<Json>())
    CountOption(
      label: '${u['label_key'] ?? ''}',
      minutes: (u['minutes'] as num?)?.toInt() ?? 0,
      price: (u['price'] as num?)?.toInt() ?? 0,
    ),
];

/// Editable draft of a counts pricing. Controllers are owned here and disposed by the caller.
class _CountsDraft {
  _CountsDraft(Json pricing)
    : rows = [for (final o in countOptionsOf(pricing)) _Row.of(o)],
      maxEach = TextEditingController(text: '${pricing['max_each'] ?? ''}'),
      discountPct = TextEditingController(
        text:
            '${((pricing['multi_discount_bps'] as num?)?.toInt() ?? 0) ~/ 100}',
      );

  final List<_Row> rows;
  final TextEditingController maxEach;
  final TextEditingController discountPct;

  List<TextEditingController> get all => [
    maxEach,
    discountPct,
    for (final r in rows) ...[r.label, r.price, r.minutes],
  ];

  int? get maxEachValue => int.tryParse(maxEach.text.trim());
  int get discountBps => (int.tryParse(discountPct.text.trim()) ?? 0) * 100;

  /// First problem with the draft, as a Korean-first message key, or null when it can be saved.
  String? problem(T t) {
    if (rows.isEmpty) return t.cntNeedOption;
    if (rows.any((r) => r.label.text.trim().isEmpty)) return t.cntNeedName;
    if (rows.any((r) => _int(r.price) <= 0 || _int(r.minutes) <= 0))
      return t.cntNeedPrice;
    final cap = maxEach.text.trim().isEmpty ? null : maxEachValue;
    if (maxEach.text.trim().isNotEmpty &&
        (cap == null || cap < 1 || cap > countsMaxEachCap)) {
      return t.cntMaxEachInvalid;
    }
    final pct = int.tryParse(discountPct.text.trim());
    if (discountPct.text.trim().isNotEmpty &&
        (pct == null || pct < 0 || pct > countsMaxDiscountPct)) {
      return t.cntDiscountInvalid;
    }
    return null;
  }

  Json toPricing() => {
    'type': 'counts',
    'units': [
      for (final r in rows)
        {
          'label_key': r.label.text.trim(),
          'minutes': _int(r.minutes),
          'price': _int(r.price),
        },
    ],
    'max_each': maxEachValue,
    'multi_discount_bps': discountBps,
  };
}

class _Row {
  _Row(this.label, this.price, this.minutes);

  factory _Row.of(CountOption o) => _Row(
    TextEditingController(text: o.label),
    TextEditingController(text: '${o.price}'),
    TextEditingController(text: '${o.minutes}'),
  );

  final TextEditingController label;
  final TextEditingController price;
  final TextEditingController minutes;
}

int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

/// Owner dialog for a counts service. Returns the new pricing JSON, or null when cancelled.
Future<Json?> askCountsPricing(BuildContext context, Json pricing) async {
  final draft = _CountsDraft(pricing);
  final result = await showDialog<Json>(
    context: context,
    builder: (_) => _CountsDialog(draft: draft),
  );
  disposeAfterClose(draft.all);
  return result;
}

class _CountsDialog extends StatefulWidget {
  const _CountsDialog({required this.draft});

  final _CountsDraft draft;

  @override
  State<_CountsDialog> createState() => _CountsDialogState();
}

class _CountsDialogState extends State<_CountsDialog> {
  /// Preview basket, one count per option.
  late List<int> _basket = List.generate(widget.draft.rows.length, (_) => 0);
  String? _error;

  _CountsDraft get _d => widget.draft;

  void _refresh([VoidCallback? change]) => setState(() {
    change?.call();
    _basket = List.of(_basket.take(_d.rows.length))
      ..addAll(List.filled(_d.rows.length - _basket.length, 0));
  });

  void _move(int i, int by) => _refresh(() {
    final j = i + by;
    if (j < 0 || j >= _d.rows.length) return;
    swapAt(_d.rows, i, j);
    swapAt(_basket, i, j);
  });

  void _save(T t) {
    final problem = _d.problem(t);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(_d.toPricing());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final options = [
      for (final r in _d.rows)
        CountOption(
          label: r.label.text.trim(),
          minutes: _int(r.minutes),
          price: _int(r.price),
        ),
    ];
    final cap = _d.maxEachValue ?? countsMaxEachCap;
    final quote = countQuote(options, _basket, _d.discountBps);
    return AlertDialog(
      title: Text(t.cntTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.cntHelp),
              const SizedBox(height: 12),
              for (var i = 0; i < _d.rows.length; i++) _optionRow(i, t),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _refresh(
                    () => _d.rows.add(
                      _Row(
                        TextEditingController(),
                        TextEditingController(),
                        TextEditingController(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(t.cntAddOption),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _field(_d.maxEach, t.cntMaxEach, _refresh)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(_d.discountPct, t.cntDiscount, _refresh),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(t.cntPreview, style: Theme.of(context).textTheme.titleSmall),
              for (var i = 0; i < _d.rows.length; i++)
                _stepper(i, cap, options[i].label, t),
              const SizedBox(height: 8),
              Text(
                t.cntPreviewTotal(
                  context.won(quote.won),
                  t.duration(quote.minutes),
                ),
              ),
              if (quote.off > 0)
                Text(t.cntPreviewDiscount(context.won(quote.off))),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(onPressed: () => _save(t), child: Text(t.save)),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    void Function([VoidCallback?]) onChanged,
  ) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, isDense: true),
    onChanged: (_) => onChanged(),
  );

  Widget _optionRow(int i, T t) {
    final r = _d.rows[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: r.label,
              decoration: InputDecoration(
                labelText: t.cntOptionName,
                isDense: true,
              ),
              onChanged: (_) => _refresh(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(flex: 2, child: _field(r.price, t.listPrice, _refresh)),
          const SizedBox(width: 6),
          Expanded(flex: 2, child: _field(r.minutes, t.cMinutes, _refresh)),
          IconButton(
            tooltip: t.cntMoveUp,
            onPressed: i == 0 ? null : () => _move(i, -1),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
          IconButton(
            tooltip: t.cntMoveDown,
            onPressed: i == _d.rows.length - 1 ? null : () => _move(i, 1),
            icon: const Icon(Icons.arrow_downward_rounded),
          ),
          IconButton(
            tooltip: t.cntRemove,
            onPressed: () => _refresh(() {
              _d.rows.removeAt(i);
              _basket.removeAt(i);
            }),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _stepper(int i, int cap, String label, T t) {
    final n = _basket[i];
    return Row(
      children: [
        Expanded(child: Text(label.isEmpty ? '-' : label)),
        IconButton(
          tooltip: t.cntLess,
          onPressed: n == 0 ? null : () => _refresh(() => _basket[i]--),
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        SizedBox(width: 28, child: Text('$n', textAlign: TextAlign.center)),
        IconButton(
          tooltip: t.cntMore,
          onPressed: n >= cap ? null : () => _refresh(() => _basket[i]++),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );
  }
}
