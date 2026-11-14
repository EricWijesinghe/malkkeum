import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'confirm_action.dart';

/// Owner-editable push and inbox text, per event and language. An empty setup keeps the built-in text.
/// Values in braces (such as the booking number) are filled in when the message is sent.
class NotifyTemplatesScreen extends StatelessWidget {
  const NotifyTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      load: () async =>
          await context.api.get('/admin/notify-templates') as Json,
      builder: (context, data, _) {
        final items = (data['items'] as List).cast<Json>();
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text(t.ntIntro, style: context.text.bodyMedium),
            const SizedBox(height: Space.md),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: _EventCard(key: ValueKey(item['kind']), item: item),
              ),
          ],
        );
      },
    );
  }
}

/// One notification: a section per language, each with its own fields, preview, save and restore.
class _EventCard extends StatefulWidget {
  const _EventCard({super.key, required this.item});

  final Json item;

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  static const _langs = ['ko', 'en'];
  final _title = <String, TextEditingController>{};
  final _body = <String, TextEditingController>{};
  final _custom = <String, bool>{};
  final _previews = <String, String>{};

  String get _kind => widget.item['kind'] as String;

  @override
  void initState() {
    super.initState();
    for (final lang in _langs) {
      final slot = widget.item[lang] as Json;
      final custom = slot['custom'] as Json?;
      final shown = (custom ?? slot['default'] as Json);
      _custom[lang] = custom != null;
      _title[lang] = TextEditingController(text: '${shown['title']}');
      _body[lang] = TextEditingController(text: '${shown['body']}');
    }
  }

  @override
  void dispose() {
    for (final c in [..._title.values, ..._body.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Json _payload(String lang) => {
    'title': _title[lang]!.text,
    'body': _body[lang]!.text,
  };

  Future<void> _save(String lang) async {
    final t = context.t;
    try {
      await context.api.put('/admin/notify-templates/$_kind/$lang', _payload(lang));
      if (!mounted) return;
      setState(() => _custom[lang] = true);
      showToast(context, t.cSaved);
    } catch (e) {
      if (mounted) showToast(context, _errorText(t, e));
    }
  }

  Future<void> _preview(String lang) async {
    final t = context.t;
    try {
      final res = await context.api.post(
        '/admin/notify-templates/preview',
        {'kind': _kind, 'locale': lang, ..._payload(lang)},
      ) as Json;
      if (!mounted) return;
      setState(() => _previews[lang] = '${res['title']}\n${res['body']}');
    } catch (e) {
      if (mounted) showToast(context, _errorText(t, e));
    }
  }

  Future<void> _restore(String lang) async {
    final t = context.t;
    if (!await confirmAction(context, t.ntRestore) || !mounted) return;
    final api = context.api;
    try {
      await api.delete('/admin/notify-templates/$_kind/$lang');
      if (!mounted) return;
      final slot = widget.item[lang] as Json;
      final built = slot['default'] as Json;
      setState(() {
        _custom[lang] = false;
        _title[lang]!.text = '${built['title']}';
        _body[lang]!.text = '${built['body']}';
        _previews.remove(lang);
      });
      showToast(context, t.ntRestored);
    } catch (e) {
      if (mounted) showToast(context, _errorText(t, e));
    }
  }

  String _errorText(T t, Object e) {
    final code = e is ApiException ? e.code : '';
    return switch (code) {
      'unknown_variable' => t.ntErrVar,
      'unbalanced_braces' => t.ntErrBraces,
      'text_empty' => t.ntErrEmpty,
      'text_too_long' => t.ntErrLong,
      'invalid_text' => t.ntErrChars,
      _ => t.error(e),
    };
  }

  Widget _langSection(T t, String lang) {
    final slot = widget.item[lang] as Json;
    final built = slot['default'] as Json;
    final canEdit = context.console.isAdmin;
    final name = lang == 'ko' ? t.ntLangKo : t.ntLangEn;
    final preview = _previews[lang];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: context.text.titleSmall),
        Text(
          '${t.ntBuiltIn}: ${built['title']} / ${built['body']}',
          style: context.text.bodySmall,
        ),
        Text(
          _custom[lang]! ? t.ntUsingCustom : t.ntUsingBuiltIn,
          style: context.text.bodySmall,
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _title[lang],
          enabled: canEdit,
          decoration: InputDecoration(labelText: t.ntTitleField),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _body[lang],
          enabled: canEdit,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(labelText: t.ntBodyField),
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            OutlinedButton(
              onPressed: () => _preview(lang),
              child: Text(t.ntPreview),
            ),
            FilledButton(
              onPressed: !canEdit ? null : () => _save(lang),
              child: Text(t.ntSave),
            ),
            TextButton(
              onPressed: !canEdit || !_custom[lang]!
                  ? null
                  : () => _restore(lang),
              child: Text(t.ntRestore),
            ),
          ],
        ),
        if (preview != null) ...[
          const SizedBox(height: Space.sm),
          Text(t.ntPreviewResult, style: context.text.labelMedium),
          Text(preview, style: context.text.bodyMedium),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final vars = (widget.item['variables'] as List).cast<String>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item['label'] as String,
              style: context.text.titleMedium,
            ),
            if (vars.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Text(
                t.ntVars(vars.map((v) => '{$v}').join(' ')),
                style: context.text.bodySmall,
              ),
            ],
            const SizedBox(height: Space.md),
            _langSection(t, 'ko'),
            const Divider(height: Space.lg),
            _langSection(t, 'en'),
          ],
        ),
      ),
    );
  }
}
