import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Registers a partner as a Toss seller. Returns the seller status the server reported, or null when cancelled.
/// The payout account is the partner's verified one on the server; only business details are typed here.
Future<String?> showTossSellerDialog(BuildContext context, String proId) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TossSellerDialog(proId: proId),
  );
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _TossSellerDialog extends StatefulWidget {
  const _TossSellerDialog({required this.proId});
  final String proId;

  @override
  State<_TossSellerDialog> createState() => _TossSellerDialogState();
}

class _TossSellerDialogState extends State<_TossSellerDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _representative = TextEditingController();
  final _registrationNo = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'individual';
  bool _busy = false;

  bool get _company => _type == 'company';

  @override
  void dispose() {
    for (final c in [_name, _representative, _registrationNo, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Json _body() => {
    'business_type': _type,
    'name': _name.text.trim(),
    if (_company) ...{
      'representative': _representative.text.trim(),
      'registration_no': _registrationNo.text.replaceAll(RegExp(r'\D'), ''),
    },
    'email': _email.text.trim(),
    'phone': _phone.text.replaceAll(RegExp(r'\D'), ''),
  };

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false) || _busy) return;
    setState(() => _busy = true);
    try {
      final r =
          await context.api.post(
                '/admin/settlements/toss-sellers/${widget.proId}',
                _body(),
              )
              as Json;
      if (mounted) Navigator.of(context).pop(r['seller_status'] as String? ?? '');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, context.t.error(e));
      }
    }
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? context.t.required : null;

  String? _digits(String? v, int count) {
    if (_required(v) != null) return context.t.required;
    return v!.replaceAll(RegExp(r'\D'), '').length == count ? null : context.t.required;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.poSellerTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.poSellerHint, style: context.text.bodySmall),
              const SizedBox(height: Space.sm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'individual', label: Text(t.poSellerIndividual)),
                  ButtonSegment(value: 'company', label: Text(t.poSellerCompany)),
                ],
                selected: {_type},
                onSelectionChanged: _busy ? null : (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: Space.sm),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                decoration: InputDecoration(labelText: t.poSellerName),
                validator: _required,
              ),
              if (_company) ...[
                TextFormField(
                  controller: _representative,
                  enabled: !_busy,
                  decoration: InputDecoration(labelText: t.poSellerRepresentative),
                  validator: _required,
                ),
                TextFormField(
                  controller: _registrationNo,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.poSellerRegNo),
                  validator: (v) => _digits(v, 10),
                ),
              ],
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t.poSellerEmail),
                validator: (v) => _required(v) ?? (_emailPattern.hasMatch(v!.trim()) ? null : t.required),
              ),
              TextFormField(
                controller: _phone,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t.poSellerPhone),
                validator: (v) {
                  final n = (v ?? '').replaceAll(RegExp(r'\D'), '').length;
                  return n == 10 || n == 11 ? null : t.required;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(t.poSellerSubmit),
        ),
      ],
    );
  }
}
