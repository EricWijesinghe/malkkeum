// Renewal calendar (갱신 일정): domain, hosting and account renewal dates. The owner gets texts 30 and 7 days
// before each date. The keys check row follows the last upload test and cannot be edited here.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

const _keysTestId = 'keys_test';
const _kinds = [
  'domain',
  'domain_alias',
  'hosting',
  'apple',
  'solapi',
  'storage',
  'other',
];

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _kindLabel(T t, String kind) => switch (kind) {
  'domain' => t.rnwKindDomain,
  'domain_alias' => t.rnwKindDomainAlias,
  'hosting' => t.rnwKindHosting,
  'apple' => t.rnwKindApple,
  'solapi' => t.rnwKindSolapi,
  'storage' => t.rnwKindStorage,
  _ => kind == _keysTestId ? t.rnwKindKeysTest : t.rnwKindOther,
};

String _daysText(T t, int left) => switch (left) {
  < 0 => t.rnwOverdue,
  0 => t.rnwToday,
  _ => t.rnwDaysLeft('$left'),
};

class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key});

  @override
  State<RenewalsScreen> createState() => _RenewalsState();
}

class _RenewalsState extends State<RenewalsScreen> {
  List<Json>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final body = (await context.api.get('/admin/renewals')) as Json;
      final rows = (body['items'] as List).cast<Json>();
      if (mounted) setState(() => _items = rows);
    } on ApiException {
      if (mounted) showToast(context, context.t.rnwLoadFailed);
    }
  }

  /// Saves a new item or a changed one, then reloads the list. Failures show a toast and keep the list.
  Future<void> _save(String? id, Json draft) async {
    try {
      if (id == null) {
        await context.api.post(
          '/admin/renewals',
          draft,
          ApiClient.newIdempotencyKey(),
        );
      } else {
        await context.api.put('/admin/renewals/$id', draft);
      }
      if (mounted) showToast(context, context.t.rnwSaved);
    } on ApiException {
      if (mounted) showToast(context, context.t.rnwFailed);
    }
    await _load();
  }

  Future<void> _edit([Json? item]) async {
    final draft = await showDialog<Json>(
      context: context,
      builder: (_) => _RenewalForm(item: item),
    );
    if (draft == null) return;
    await _save(item?['id'] as String?, draft);
  }

  Future<void> _delete(Json item) async {
    final t = context.t;
    final api = context.api;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.rnwDelete),
        content: Text(t.rnwDeleteAsk),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.rnwCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.rnwDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.delete('/admin/renewals/${item['id']}');
      if (mounted) showToast(context, context.t.rnwDeleted);
    } on ApiException {
      if (mounted) showToast(context, context.t.rnwFailed);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final items = _items;
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        Text(t.rnwTitle, style: context.text.headlineMedium),
        const SizedBox(height: Space.xs),
        Text(t.rnwIntro, style: context.text.bodySmall),
        const SizedBox(height: Space.md),
        // Not inside a Row: the theme's full-width minimum size needs a bounded width.
        FilledButton.icon(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: Text(t.rnwAdd),
        ),
        const SizedBox(height: Space.md),
        if (items == null)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          Text(t.rnwEmpty)
        else
          for (final item in items) _row(t, item),
      ],
    );
  }

  Widget _row(T t, Json item) {
    final keys = item['id'] == _keysTestId;
    final left = item['days_left'] as int;
    return Card(
      child: ListTile(
        title: Text(item['name'] as String),
        subtitle: Text(
          '${_kindLabel(t, item['kind'] as String)} · ${t.rnwDate}: ${item['due_on']}',
        ),
        leading: Text(_daysText(t, left), style: context.text.labelLarge),
        trailing: keys
            ? null
            : Wrap(
                spacing: Space.xs,
                children: [
                  IconButton(
                    tooltip: t.rnwEdit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(item),
                  ),
                  IconButton(
                    tooltip: t.rnwDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(item),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Add or edit one item. Pops the request body, or null when cancelled.
class _RenewalForm extends StatefulWidget {
  const _RenewalForm({this.item});

  final Json? item;

  @override
  State<_RenewalForm> createState() => _RenewalFormState();
}

class _RenewalFormState extends State<_RenewalForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.item?['name'] as String? ?? '',
  );
  late String _kind = widget.item?['kind'] as String? ?? 'domain';
  late DateTime? _due = widget.item?['due_on'] == null
      ? null
      : DateTime.parse(widget.item!['due_on'] as String);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _submit() {
    final t = context.t;
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 80) {
      setState(() => _error = t.rnwNameError);
      return;
    }
    final due = _due;
    if (due == null) {
      setState(() => _error = t.rnwDateError);
      return;
    }
    Navigator.of(
      context,
    ).pop({'kind': _kind, 'name': name, 'due_on': _fmtDate(due)});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final due = _due;
    return AlertDialog(
      title: Text(widget.item == null ? t.rnwAdd : t.rnwEdit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: t.rnwName, isDense: true),
              ),
              const SizedBox(height: Space.md),
              Text(t.rnwKind, style: context.text.titleSmall),
              Wrap(
                spacing: Space.xs,
                children: [
                  for (final k in _kinds)
                    ChoiceChip(
                      label: Text(_kindLabel(t, k)),
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                ],
              ),
              const SizedBox(height: Space.md),
              Text(t.rnwDate, style: context.text.titleSmall),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(due == null ? t.rnwPickDate : _fmtDate(due)),
              ),
              const SizedBox(height: Space.sm),
              Text(t.rnwSmsNote, style: context.text.bodySmall),
              if (_error != null) ...[
                const SizedBox(height: Space.sm),
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
          child: Text(t.rnwCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(t.rnwSave)),
      ],
    );
  }
}
