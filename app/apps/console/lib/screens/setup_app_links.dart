import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Owner-editable app link values for Naver sign-in. Saved values replace the server's env values as a set.
class AppLinksCard extends StatelessWidget {
  const AppLinksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<Json>(
      load: () async => await context.api.get('/admin/app-links') as Json,
      builder: (context, data, reload) =>
          _AppLinksForm(initial: data, onSaved: reload),
    );
  }
}

class _AppLinksForm extends StatefulWidget {
  const _AppLinksForm({required this.initial, required this.onSaved});

  final Json initial;
  final Future<void> Function() onSaved;

  @override
  State<_AppLinksForm> createState() => _AppLinksFormState();
}

class _AppLinksFormState extends State<_AppLinksForm> {
  late final _certs = TextEditingController(
    text: (widget.initial['android_cert_sha256'] as List).join('\n'),
  );
  late final _team = TextEditingController(
    text: (widget.initial['apple_team_id'] as String?) ?? '',
  );
  Json? _checked;
  late bool _fromDb = widget.initial['source'] == 'database';

  @override
  void dispose() {
    _certs.dispose();
    _team.dispose();
    super.dispose();
  }

  Json _body() {
    final team = _team.text.trim();
    return {
      'android_cert_sha256': _certs.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'apple_team_id': team.isEmpty ? null : team,
    };
  }

  Future<void> _check() async {
    final t = context.t;
    try {
      final result = await context.api.post('/admin/app-links/verify', _body());
      if (!mounted) return;
      setState(() => _checked = result as Json);
      showToast(context, t.cAppLinkChecked);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  Future<void> _save() async {
    final t = context.t;
    try {
      await context.api.put('/admin/app-links', _body());
      if (!mounted) return;
      setState(() => _fromDb = true);
      showToast(context, t.cSaved);
      await widget.onSaved();
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cAppLinkTitle, style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          Text(t.cAppLinkHint, style: context.text.bodySmall),
          const SizedBox(height: Space.xs),
          Text(
            _fromDb ? t.cAppLinkSourceDb : t.cAppLinkSourceEnv,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _certs,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: t.cAppLinkAndroidLabel,
              helperText: t.cAppLinkAndroidHint,
            ),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _team,
            decoration: InputDecoration(labelText: t.cAppLinkTeamLabel),
          ),
          if (_checked != null) ...[
            const SizedBox(height: Space.md),
            _CheckResult(result: _checked!),
          ],
          const SizedBox(height: Space.md),
          Row(
            children: [
              OutlinedButton(onPressed: _check, child: Text(t.cAppLinkCheck)),
              const SizedBox(width: Space.sm),
              FilledButton(
                onPressed: !context.console.isAdmin ? null : _save,
                child: Text(t.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckResult extends StatelessWidget {
  const _CheckResult({required this.result});

  final Json result;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final android = result['assetlinks'] != null;
    final ios = result['aasa'] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          android ? t.cAppLinkAndroidOn : t.cAppLinkAndroidOff,
          style: context.text.bodyMedium,
        ),
        Text(
          ios ? t.cAppLinkIosOn : t.cAppLinkIosOff,
          style: context.text.bodyMedium,
        ),
        if (!android || !ios) Text(t.cAppLinkNone, style: context.text.bodySmall),
        Text(t.cAppLinkChecked, style: context.text.bodySmall),
      ],
    );
  }
}
