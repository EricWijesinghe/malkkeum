import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// PIPA 동의 관리: required consents are shown checked and locked on, marketing can be withdrawn at any time.
/// Saving sends every item with the policy version the server reported, so a consent always names the text shown.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  Json? _state;
  final Map<String, bool> _granted = {};
  bool _saving = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context.app reads an inherited widget, so loading starts here rather than in initState.
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final s = await context.app.api.get('/me/consents') as Json;
    if (!mounted) return;
    setState(() {
      _state = s;
      for (final item in (s['items'] as List).cast<Json>()) {
        _granted[item['kind'] as String] = item['granted'] as bool;
      }
    });
  }

  String _label(T t, String kind) => switch (kind) {
    'terms' => t.pvTerms,
    'privacy' => t.pvPrivacy,
    'overseas_transfer' => t.pvOverseas,
    _ => t.pvMarketing,
  };

  Future<void> _save(T t) async {
    final s = _state;
    if (s == null) return;
    setState(() => _saving = true);
    try {
      final body = {
        'consents': [
          for (final kind in _granted.keys)
            {'kind': kind, 'granted': _granted[kind], 'version': s['version']},
        ],
      };
      final next = await context.app.api.put('/me/consents', body) as Json;
      if (!mounted) return;
      setState(() => _state = next);
      showToast(context, t.pvSaved);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = _state;
    return Scaffold(
      appBar: AppBar(title: Text(t.pvManage)),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Space.gutter),
              children: [
                if (s['reconsent_required'] == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.lg),
                    child: Text(t.pvReconsent, style: context.text.bodyMedium),
                  ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final item in (s['items'] as List).cast<Json>())
                        CheckboxListTile(
                          key: ValueKey('consent-${item['kind']}'),
                          value: _granted[item['kind']] ?? false,
                          title: Text(_label(t, item['kind'] as String)),
                          subtitle: item['kind'] == 'marketing'
                              ? Text(t.pvMarketingHint)
                              : null,
                          secondary: Text(
                            item['required'] == true
                                ? t.required
                                : t.pvOptional,
                            style: context.text.labelSmall,
                          ),
                          onChanged: item['required'] == true
                              ? null
                              : (v) => setState(
                                  () => _granted[item['kind'] as String] =
                                      v ?? false,
                                ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: _saving ? null : () => _save(t),
                  child: Text(t.save),
                ),
              ],
            ),
    );
  }
}

/// 열람 요구: shows everything the server holds about the customer as JSON, with a copy button.
Future<void> showDataExport(BuildContext context) async {
  final t = context.t;
  final api = context.app.api;
  try {
    final doc = await api.get('/me/export');
    if (!context.mounted) return;
    final text = const JsonEncoder.withIndent('  ').convert(doc);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.pvExport),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.pvExportHint, style: ctx.text.bodySmall),
                const SizedBox(height: Space.md),
                SelectableText(text, style: ctx.text.bodySmall),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) showToast(ctx, t.pvCopied);
            },
            child: Text(t.pvCopy),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.close),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) showToast(context, t.pvExportFailed);
  }
}
