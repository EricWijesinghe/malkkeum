import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'i18n.dart';
import 'pay_i18n.dart';
import 'social_auth.dart';

String _pretty(String digits) {
  if (digits.length < 4) return digits;
  if (digits.length < 8) return '${digits.substring(0, 3)}-${digits.substring(3)}';
  final mid = digits.length == 11 ? 7 : 6;
  return '${digits.substring(0, 3)}-${digits.substring(3, mid)}-${digits.substring(mid)}';
}

/// Verifies a phone for a social account that has none yet. Two steps on one screen:
/// number, then the 6-digit code. Pops `true` once attached.
class PhoneAttachScreen extends StatefulWidget {
  const PhoneAttachScreen({super.key, required this.api, required this.audience});

  final ApiClient api;
  final String audience;

  @override
  State<PhoneAttachScreen> createState() => _PhoneAttachScreenState();
}

class _PhoneAttachScreenState extends State<PhoneAttachScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  int _left = 0;
  Timer? _timer;

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _validPhone => RegExp(r'^01[016789]\d{7,8}$').hasMatch(_digits);

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) showToast(context, context.t.payError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        final r = await widget.api.post('/auth/otp', {'phone': _digits}) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _sent = true;
          final dev = r['dev_code'] as String?;
          if (dev != null) _code.text = dev;
        });
        _startCountdown();
      });

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _left = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left > 0 ? _left-- : t.cancel());
    });
  }

  Future<void> _verify() => _run(() async {
        await attachPhone(widget.api, audience: widget.audience, phone: _digits, code: _code.text);
        if (mounted) Navigator.of(context).pop(true);
      });

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        Text(_sent ? t.loginCodeTitle : t.apPhoneAttachTitle, style: context.text.headlineSmall),
        const SizedBox(height: Space.xs),
        Text(_sent ? t.loginCodeSentTo(_pretty(_digits)) : t.apPhoneAttachBody, style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted)),
        const SizedBox(height: Space.xl),
        if (!_sent)
          TextField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            style: context.text.headlineSmall,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              TextInputFormatter.withFunction((_, v) => TextEditingValue(text: _pretty(v.text), selection: TextSelection.collapsed(offset: _pretty(v.text).length))),
            ],
            decoration: InputDecoration(hintText: t.loginPhoneHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _validPhone ? _send() : null,
          )
        else ...[
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            style: context.text.headlineMedium?.copyWith(letterSpacing: 12),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: const InputDecoration(hintText: '••••••'),
            onChanged: (v) => v.length == 6 ? _verify() : setState(() {}),
          ),
          Center(child: TextButton(onPressed: _busy || _left > 0 ? null : _send, child: Text(_left == 0 ? t.loginResend : '${t.loginResend} ($_left)'))),
        ],
      ]),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: _sent ? t.loginVerify : t.loginSendCode,
          busy: _busy,
          onPressed: _sent ? (_code.text.length == 6 ? _verify : null) : (_validPhone ? _send : null),
        ),
      ),
    );
  }
}
