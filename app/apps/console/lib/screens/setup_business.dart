import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Brand colours offered as one-tap swatches; any #RRGGBB can still be typed.
const _swatches = ['#3B5BFD', '#00B386', '#FF6B3D', '#8B5CF6', '#E11D74', '#0EA5E9', '#F59E0B', '#111827'];

Color? parseHex(String s) {
  final v = s.trim().replaceFirst('#', '');
  if (v.length != 6) return null;
  final n = int.tryParse(v, radix: 16);
  return n == null ? null : Color(0xFF000000 | n);
}

/// Business profile: name, support contact, logo, brand colour and the legal footer details.
class BusinessCard extends StatefulWidget {
  const BusinessCard({super.key, required this.initial, required this.onSaved});
  final Json initial;
  final VoidCallback onSaved;

  @override
  State<BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<BusinessCard> {
  static const _top = ['name', 'support_phone', 'support_email', 'support_hours'];
  static const _company = ['legal_name', 'ceo', 'registration_no', 'mail_order_no', 'address', 'privacy_officer'];
  static const _links = ['app_store_url', 'play_store_url', 'partner_app_store_url', 'partner_play_store_url'];

  late final Map<String, TextEditingController> _c;
  late final TextEditingController _color;
  String? _logo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final company = (widget.initial['company'] as Json?) ?? const {};
    _c = {
      for (final k in _top) k: TextEditingController(text: widget.initial[k] as String? ?? ''),
      for (final k in _company) 'company.$k': TextEditingController(text: company[k] as String? ?? ''),
      for (final k in _links) k: TextEditingController(text: widget.initial[k] as String? ?? ''),
    };
    _color = TextEditingController(text: widget.initial['primary_color'] as String? ?? _swatches.first)..addListener(() => setState(() {}));
    _logo = widget.initial['logo_url'] as String?;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _color.dispose();
    super.dispose();
  }

  String _label(T t, String k) => switch (k) {
    'name' => t.cSetupBusinessName,
    'support_phone' => t.cSetupSupportPhone,
    'support_email' => t.cSetupSupportEmail,
    'support_hours' => t.cSetupSupportHours,
    'company.legal_name' => t.cSetupLegalName,
    'company.ceo' => t.cSetupCeo,
    'company.registration_no' => t.cSetupRegNo,
    'company.mail_order_no' => t.cSetupMailOrderNo,
    'company.address' => t.cSetupAddress,
    'app_store_url' => 'App Store · ${t.cSetupCustomerApp}',
    'play_store_url' => 'Google Play · ${t.cSetupCustomerApp}',
    'partner_app_store_url' => 'App Store · ${t.cSetupPartnerApp}',
    'partner_play_store_url' => 'Google Play · ${t.cSetupPartnerApp}',
    _ => t.cSetupPrivacyOfficer,
  };

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (file == null || !mounted) return;
    final api = context.api;
    setState(() => _busy = true);
    try {
      final url = await api.upload(await file.readAsBytes(), file.name);
      if (mounted) setState(() => _logo = url);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final t = context.t;
    setState(() => _busy = true);
    try {
      await context.api.put('/admin/setup/business', {
        for (final k in _top) k: _c[k]!.text,
        for (final k in _links) k: _c[k]!.text,
        'primary_color': _color.text,
        'logo_url': _logo,
        'company': {for (final k in _company) k: _c['company.$k']!.text},
      });
      if (!mounted) return;
      showToast(context, t.cSetupSaved);
      widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.status == 400 ? t.cInvalidValue : t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final brand = parseHex(_color.text) ?? context.primary;
    final done = (widget.initial['name'] as String?)?.isNotEmpty ?? false;
    Widget field(String k) => Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TextField(controller: _c[k], decoration: InputDecoration(labelText: _label(t, k))),
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !done,
          tilePadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
          childrenPadding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
          leading: Icon(done ? Icons.check_circle_rounded : Icons.storefront_rounded, color: done ? context.primary : null),
          title: Text(t.cSetupBusiness, style: context.text.titleMedium),
          children: [
            _Preview(name: _c['name']!.text, color: brand, logo: _logo, onPick: _busy ? null : _pickLogo, pickLabel: t.cSetupLogo),
            const SizedBox(height: Space.md),
            for (final k in _top) field(k),
            Text(t.cSetupColor, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
              for (final s in _swatches)
                Semantics(
                  button: true,
                  label: s,
                  child: InkResponse(
                    onTap: () => _color.text = s,
                    radius: 28,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: parseHex(s),
                        shape: BoxShape.circle,
                        border: Border.all(color: _color.text.toUpperCase() == s ? context.colors.ink : Colors.transparent, width: 3),
                      ),
                    ),
                  ),
                ),
              SizedBox(width: 130, child: TextField(controller: _color, decoration: const InputDecoration(labelText: '#RRGGBB', isDense: true))),
            ]),
            const SizedBox(height: Space.lg),
            Text(t.cSetupCompany, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            for (final k in _company) field('company.$k'),
            const SizedBox(height: Space.md),
            Text(t.cSetupStoreLinks, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            for (final k in _links) field(k),
            const SizedBox(height: Space.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.save_rounded), label: Text(t.cSetupSave)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live preview of the app header with the chosen name, logo and colour.
class _Preview extends StatelessWidget {
  const _Preview({required this.name, required this.color, required this.logo, required this.onPick, required this.pickLabel});
  final String name;
  final Color color;
  final String? logo;
  final VoidCallback? onPick;
  final String pickLabel;

  @override
  Widget build(BuildContext context) {
    final onColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.35)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Row(children: [
        Semantics(
          button: true,
          label: pickLabel,
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: onColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: logo == null ? Icon(Icons.add_photo_alternate_rounded, color: onColor) : Image.network(logo!, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Text(name.isEmpty ? BrandConfig.placeholder.name : name, style: context.text.headlineSmall?.copyWith(color: onColor, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
