import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../download.dart';
import '../state.dart';

/// Second factor after a staff password. Enrolled staff enter a TOTP or recovery code. Admins without
/// TOTP set it up first and keep the one-time recovery codes before the console opens. Tokens are only
/// saved once the owner continues, so the console never opens over the codes.
class StaffMfaPanel extends StatefulWidget {
  const StaffMfaPanel({
    super.key,
    required this.challenge,
    required this.onCancel,
  });
  final StaffMfaChallenge challenge;
  final VoidCallback onCancel;

  @override
  State<StaffMfaPanel> createState() => _StaffMfaPanelState();
}

class _StaffMfaPanelState extends State<StaffMfaPanel> {
  final _code = TextEditingController();
  bool _recovery = false;
  bool _busy = false;
  String? _error;
  Json? _enrol;
  Json? _tokens;
  List<String>? _codes;

  Session get _session => Deps.read(context).session;

  @override
  void initState() {
    super.initState();
    if (widget.challenge.enrol) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// One server step: busy while in flight, a readable message on failure.
  Future<void> _run(Future<void> Function() step) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await step();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(ApiException e) {
    final t = context.t;
    return switch (e.status) {
      401 => t.cMfaExpired,
      429 => t.cMfaLocked,
      400 when e.code == 'mfa_invalid_code' => t.cMfaInvalid,
      _ => t.error(e),
    };
  }

  Future<void> _start() => _run(() async {
    _enrol = await _session.staffMfaEnrolStart(widget.challenge.token);
  });

  Future<void> _verify() => _run(
    () => _session.staffMfaVerify(
      widget.challenge.token,
      code: _recovery ? null : _code.text.trim(),
      recoveryCode: _recovery ? _code.text.trim() : null,
    ),
  );

  Future<void> _confirm() => _run(() async {
    final r = await _session.staffMfaEnrolConfirm(
      widget.challenge.token,
      _code.text.trim(),
    );
    setState(() {
      _tokens = r;
      _codes = [for (final c in r['recovery_codes'] as List) c as String];
    });
  });

  Future<void> _continue() => _run(() => _session.save(_tokens!));

  void _submit() {
    if (_busy) return;
    if (widget.challenge.enrol && _codes == null) {
      _confirm();
    } else if (!widget.challenge.enrol) {
      _verify();
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showToast(context, context.t.cMfaCopied);
  }

  Future<void> _download() async {
    final t = context.t;
    final ok = await saveCsv(
      utf8.encode('${_codes!.join('\n')}\n'),
      'malkkeum-recovery-codes.txt',
    );
    if (mounted) showToast(context, ok ? t.cDone : t.cMfaSaveFailed);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final children = <Widget>[
      Text(
        _codes != null
            ? t.cMfaCodesTitle
            : widget.challenge.enrol
            ? t.cMfaEnrolTitle
            : t.cMfaTitle,
        style: context.text.headlineSmall,
      ),
      const SizedBox(height: Space.sm),
      if (_codes != null)
        ..._codesView(t)
      else if (widget.challenge.enrol)
        ..._enrolView(t)
      else
        ..._verifyView(t),
      if (_error != null) ...[
        const SizedBox(height: Space.sm),
        Text(_error!, style: TextStyle(color: context.colors.danger)),
      ],
      const SizedBox(height: Space.lg),
      if (_codes != null)
        PrimaryButton(label: t.cMfaContinue, busy: _busy, onPressed: _continue)
      else
        PrimaryButton(
          label: widget.challenge.enrol ? t.cMfaConfirm : t.cMfaVerify,
          busy: _busy,
          onPressed: _submitEnabled ? _submit : null,
        ),
      if (_codes == null)
        TextButton(
          onPressed: _busy ? null : widget.onCancel,
          child: Text(t.cMfaBack),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  bool get _submitEnabled => !widget.challenge.enrol || _enrol != null;

  List<Widget> _verifyView(T t) => [
    TextField(
      controller: _code,
      keyboardType: _recovery ? TextInputType.text : TextInputType.number,
      autofocus: true,
      decoration: InputDecoration(
        labelText: _recovery ? t.cMfaRecovery : t.cMfaCode,
      ),
      onSubmitted: (_) => _submit(),
    ),
    TextButton(
      onPressed: _busy
          ? null
          : () => setState(() {
              _recovery = !_recovery;
              _code.clear();
              _error = null;
            }),
      child: Text(_recovery ? t.cMfaUseCode : t.cMfaUseRecovery),
    ),
  ];

  List<Widget> _enrolView(T t) {
    final enrol = _enrol;
    if (enrol == null) {
      return const [Center(child: CircularProgressIndicator())];
    }
    return [
      Text(t.cMfaEnrolBody, style: context.text.bodyMedium),
      const SizedBox(height: Space.md),
      _CopyField(
        label: t.cMfaSecret,
        value: enrol['secret'] as String,
        onCopy: _copy,
        copyLabel: t.cMfaCopy,
      ),
      const SizedBox(height: Space.sm),
      _CopyField(
        label: t.cMfaLink,
        value: enrol['otpauth_uri'] as String,
        onCopy: _copy,
        copyLabel: t.cMfaCopy,
      ),
      const SizedBox(height: Space.md),
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: t.cMfaCode),
        onSubmitted: (_) => _submit(),
      ),
    ];
  }

  List<Widget> _codesView(T t) => [
    Text(t.cMfaCodesBody, style: context.text.bodyMedium),
    const SizedBox(height: Space.md),
    Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: SelectableText(
          _codes!.join('\n'),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ),
    ),
    const SizedBox(height: Space.sm),
    Wrap(
      spacing: Space.sm,
      children: [
        OutlinedButton.icon(
          onPressed: () => _copy(_codes!.join('\n')),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(t.cMfaCopy),
        ),
        OutlinedButton.icon(
          onPressed: _download,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(t.cMfaDownload),
        ),
      ],
    ),
  ];
}

/// A value shown for manual entry, with its own copy button.
class _CopyField extends StatelessWidget {
  const _CopyField({
    required this.label,
    required this.value,
    required this.onCopy,
    required this.copyLabel,
  });
  final String label;
  final String value;
  final Future<void> Function(String) onCopy;
  final String copyLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.text.labelMedium),
      Row(
        children: [
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            tooltip: copyLabel,
            onPressed: () => onCopy(value),
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    ],
  );
}
