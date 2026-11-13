import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state.dart';
import 'setup_app_links.dart';
import 'setup_business.dart';
import 'setup_guides.dart';
import 'setup_pay_methods.dart';
import 'setup_review.dart';

/// Owner's launch checklist: business profile plus one card per external service.
/// Keys are typed here (never in config files), saved encrypted, and tested on the spot.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _view = GlobalKey<AsyncViewState<Json>>();

  void _reload() => _view.currentState?.reload();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      key: _view,
      load: () async => await context.api.get('/admin/setup') as Json,
      builder: (context, data, reload) {
        final cards = (data['integrations'] as List).cast<Json>();
        final business = (data['business'] as Json?) ?? const {};
        final done =
            cards.where((c) => c['configured'] == true).length +
            (business['name'] != null ? 1 : 0);
        final total = cards.length + 1;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                _Header(
                  done: done,
                  total: total,
                  devMode: data['dev_mode'] == true,
                ),
                const SizedBox(height: Space.lg),
                BusinessCard(initial: business, onSaved: _reload),
                const SizedBox(height: Space.md),
                const PayMethodsCard(),
                const SizedBox(height: Space.md),
                ReviewAccountCard(
                  current: data['review_account'] as Json?,
                  onChanged: _reload,
                ),
                const SizedBox(height: Space.md),
                HeartbeatCard(configured: data['heartbeat_configured'] == true),
                const SizedBox(height: Space.md),
                const AppLinksCard(),
                for (final c in cards) ...[
                  const SizedBox(height: Space.md),
                  IntegrationCard(
                    key: ValueKey(c['code']),
                    card: c,
                    webhookUrl: data['webhook_url'] as String?,
                    onChanged: _reload,
                  ),
                ],
                const SizedBox(height: Space.xl),
                Text(
                  t.cSetupProgress('$done', '$total'),
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.done,
    required this.total,
    required this.devMode,
  });
  final int done;
  final int total;
  final bool devMode;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final finished = done == total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                finished
                    ? Icons.rocket_launch_rounded
                    : Icons.checklist_rounded,
                color: context.primary,
                size: 28,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  finished ? t.cSetupAllDone : t.cSetupTitle,
                  style: context.text.titleLarge,
                ),
              ),
              Flexible(
                child: Text(
                  t.cSetupProgress('$done', '$total'),
                  textAlign: TextAlign.end,
                  style: context.text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total == 0 ? 0 : done / total),
              duration: const Duration(milliseconds: 600),
              curve: Motion.ease,
              builder: (_, v, _) =>
                  LinearProgressIndicator(value: v, minHeight: 10),
            ),
          ),
          if (devMode) ...[
            const SizedBox(height: Space.md),
            Row(
              children: [
                const Icon(Icons.science_rounded, size: 18),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(t.cSetupDevMode, style: context.text.bodySmall),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One external service: status, the how-to steps, the fields, save / test / disconnect.
class IntegrationCard extends StatefulWidget {
  const IntegrationCard({
    super.key,
    required this.card,
    required this.onChanged,
    this.webhookUrl,
  });
  final Json card;
  final VoidCallback onChanged;
  final String? webhookUrl;

  @override
  State<IntegrationCard> createState() => _IntegrationCardState();
}

class _IntegrationCardState extends State<IntegrationCard> {
  final _text = <String, TextEditingController>{};
  final _map = <String, Map<String, TextEditingController>>{};
  // Null until the owner touches a switch or it is saved; an untouched switch is not sent (env default stays).
  final _toggles = <String, bool?>{};
  bool _busy = false;
  Json? _result;

  String get _code => widget.card['code'] as String;
  Guide get _guide => guides[_code]!;
  List<Json> get _fields => (widget.card['fields'] as List).cast<Json>();

  @override
  void initState() {
    super.initState();
    _result = widget.card['last_test'] as Json?;
    for (final f in _fields) {
      final name = f['name'] as String;
      final kind = f['kind'] as String;
      final preview = f['preview'];
      if (kind == 'map') {
        final saved = preview is Map
            ? preview.cast<String, dynamic>()
            : const <String, dynamic>{};
        final keys = {
          ..._guide.fields[name]?.suggestions ?? const <String>[],
          ...saved.keys,
        };
        _map[name] = {
          for (final k in keys)
            k: TextEditingController(text: saved[k] as String? ?? ''),
        };
      } else if (kind == 'toggle') {
        _toggles[name] = f['set'] == true ? preview == true : null;
      } else {
        final show = kind == 'text' || kind == 'list';
        final text = preview is List
            ? preview.join(', ')
            : (preview as String? ?? '');
        _text[name] = TextEditingController(text: show ? text : '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final m in _map.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Json _body() => {
    for (final e in _text.entries)
      if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    for (final e in _toggles.entries)
      if (e.value != null) e.key: e.value,
    for (final e in _map.entries)
      e.key: {
        for (final m in e.value.entries)
          if (m.value.text.trim().isNotEmpty) m.key: m.value.text.trim(),
      },
  };

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException && e.status == 400
              ? setupMessage(context.t, e.code)
              : context.t.error(e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final r = await context.api.post('/admin/setup/$_code/test') as Json;
    if (mounted) setState(() => _result = r);
  }

  Future<void> _save() => _run(() async {
    await context.api.put('/admin/setup/$_code', _body());
    if (!mounted) return;
    showToast(context, context.t.cSetupSaved);
    await _test();
    widget.onChanged();
  });

  Future<void> _clear() => _run(() async {
    await context.api.delete('/admin/setup/$_code');
    widget.onChanged();
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final configured = widget.card['configured'] == true;
    final ok = _result?['ok'] == true;
    final status = !configured
        ? Tag(label: t.cSetupNotConnected, hue: StatusHues.consultation)
        : widget.card['source'] == 'env'
        ? Tag(label: t.cSetupFromEnv, hue: StatusHues.assigned)
        : _result == null
        ? Tag(label: t.cSetupSaved, hue: StatusHues.confirmed)
        : Tag(
            label: setupMessage(t, _result!['code'] as String),
            hue: ok ? StatusHues.assigned : StatusHues.cancelled,
          );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          initiallyExpanded: !configured,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            Space.lg,
            0,
            Space.lg,
            Space.lg,
          ),
          leading: Icon(
            configured
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: configured ? context.primary : null,
          ),
          title: Text(_guide.title(t), style: context.text.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(alignment: Alignment.centerLeft, child: status),
          ),
          children: [
            _Steps(guide: _guide),
            if (_code == 'portone' && widget.webhookUrl != null)
              _CopyRow(label: t.cSetupWebhook, value: widget.webhookUrl!),
            const SizedBox(height: Space.md),
            for (final f in _fields) _field(context, f),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(t.cSetupSave),
                ),
                if (configured)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(_test),
                    icon: const Icon(Icons.wifi_tethering_rounded),
                    label: Text(t.cSetupTest),
                  ),
                if (widget.card['source'] == 'console')
                  TextButton(
                    onPressed: _busy ? null : _clear,
                    child: Text(t.cSetupClear),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, Json f) {
    final t = context.t;
    final name = f['name'] as String;
    final kind = f['kind'] as String;
    final g = _guide.fields[name];
    final label =
        '${localFields['$_code.$name']?.label(t) ?? g?.label.of(context.lang) ?? name}${f['required'] == true ? '' : ' (${t.cSetupOptional})'}';
    final saved = f['set'] == true;
    if (kind == 'map') {
      return Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            for (final e in _map[name]!.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: TextField(
                  controller: e.value,
                  decoration: InputDecoration(labelText: e.key, isDense: true),
                ),
              ),
          ],
        ),
      );
    }
    final preview = f['preview'];
    if (kind == 'toggle') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: _toggles[name] ?? preview == true,
        onChanged: (on) => setState(() => _toggles[name] = on),
      );
    }
    final hidden = kind == 'secret' || kind == 'file';
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TextField(
        controller: _text[name],
        obscureText: kind == 'secret',
        maxLines: kind == 'file' ? 6 : 1,
        minLines: 1,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: label,
          helperText: hidden && saved
              ? '${t.cSetupKeepValue} · ${preview ?? ''}'
              : localFields['$_code.$name']?.hint(t) ??
                    g?.hint?.of(context.lang),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.guide});
  final Guide guide;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(t.cSetupGuide, style: context.text.labelLarge),
            ),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(guide.site),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(t.cSetupOpenSite),
            ),
          ],
        ),
        if (guide.devHelp)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Chip(
              avatar: const Icon(Icons.engineering_rounded, size: 18),
              label: Text(
                const Tr('개발자 첫 도움 필요', 'Needs a developer the first time').of(context.lang),
              ),
            ),
          ),
        for (final (i, step) in guide.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 11,
                  child: Text('${i + 1}', style: context.text.labelSmall),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    step.of(context.lang),
                    style: context.text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        for (final shot in guide.screenshots)
          Container(
            height: 120,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: Space.sm),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(shot.of(context.lang), style: context.text.bodySmall),
          ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.sm),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: context.text.labelLarge),
      subtitle: SelectableText(value),
      trailing: IconButton(
        tooltip: context.t.cCopied,
        icon: const Icon(Icons.copy_rounded),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) showToast(context, context.t.cCopied);
        },
      ),
    ),
  );
}

/// Read-only checklist item: the uptime ping URL is set by install.sh, never typed in the console.
class HeartbeatCard extends StatelessWidget {
  const HeartbeatCard({super.key, required this.configured});
  final bool configured;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = configured ? context.colors.fresh : context.colors.sun;
    return AppCard(
      child: Row(
        children: [
          Icon(configured ? Icons.favorite_rounded : Icons.heart_broken_rounded, color: color),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.oHeartbeat, style: context.text.titleSmall),
                Text(configured ? t.oHeartbeatOn : t.oHeartbeatOff, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
