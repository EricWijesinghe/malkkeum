import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Feature switches and maintenance mode (`GET/PUT /admin/config`). Apps read the same document within 30 s.
class FlagsCard extends StatefulWidget {
  const FlagsCard({super.key, required this.initial, required this.onSaved});
  final Json initial;
  final VoidCallback onSaved;

  @override
  State<FlagsCard> createState() => _FlagsCardState();
}

final _flagLabels = <String, String Function(T)>{
  'booking': (T t) => t.oFlagBooking,
  'chat': (T t) => t.oFlagChat,
  'ai': (T t) => t.oFlagAi,
  'payments': (T t) => t.oFlagPayments,
};

class _FlagsCardState extends State<FlagsCard> {
  late final Map<String, bool> _flags;
  late bool _maintenance;
  late final TextEditingController _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final saved = (widget.initial['flags'] as Map?) ?? const {};
    _flags = {for (final k in _flagLabels.keys) k: saved[k] as bool? ?? true};
    final m = (widget.initial['maintenance'] as Map?) ?? const {};
    _maintenance = m['on'] as bool? ?? false;
    _message = TextEditingController(text: m['message'] as String? ?? '');
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await context.api.put('/admin/config', {
        'flags': _flags,
        'maintenance': {'on': _maintenance, 'message': _message.text.trim()},
      });
      messenger.showSnackBar(SnackBar(content: Text(t.oSaved)));
      widget.onSaved();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.oSaveFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canSave = context.console.isAdmin;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in _flagLabels.entries)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value(t)),
              value: _flags[e.key] ?? true,
              onChanged: canSave ? (v) => setState(() => _flags[e.key] = v) : null,
            ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.oMaintenance),
            subtitle: Text(t.oMaintenanceHint),
            value: _maintenance,
            onChanged: canSave ? (v) => setState(() => _maintenance = v) : null,
          ),
          TextField(
            controller: _message,
            enabled: canSave,
            maxLength: 200,
            decoration: InputDecoration(labelText: t.oMaintenanceMessage),
          ),
          const SizedBox(height: Space.md),
          if (canSave) PrimaryButton(label: t.oSave, busy: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

/// Latest client error reports (`GET /admin/client-errors`). Already PII-scrubbed server-side.
class ClientErrorsCard extends StatelessWidget {
  const ClientErrorsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<List<Json>>(
      load: () async {
        final res = await context.api.get('/admin/client-errors', query: {'limit': '50'});
        return (res['items'] as List).cast<Json>();
      },
      builder: (context, items, reload) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.oClientErrorsHint, style: context.text.bodySmall),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                child: Text(t.oClientErrorsEmpty),
              ),
            for (final e in items) _ErrorRow(item: e),
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.item});
  final Json item;

  @override
  Widget build(BuildContext context) {
    final at = item['at'] as String;
    final when = at.length > 16 ? at.substring(0, 16).replaceFirst('T', ' ') : at;
    final stack = item['stack'] as String? ?? '';
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(item['message'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${item['app']} · ${item['version']} · $when'),
      children: [
        if (stack.isNotEmpty) SelectableText(stack, style: context.text.bodySmall),
      ],
    );
  }
}
