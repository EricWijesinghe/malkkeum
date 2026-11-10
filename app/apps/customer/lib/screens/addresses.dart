import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.moreAddresses)),
      body: app.addresses.isEmpty
          ? EmptyState(icon: Icons.home_work_rounded, title: t.addressEmpty, hue: ServiceHues.moveIn)
          : ListView(padding: const EdgeInsets.all(Space.gutter), children: [
              for (final a in app.addresses)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: AppCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AddressFormScreen(existing: a))),
                    child: Row(children: [
                      Icon(a.kind == 'office' ? Icons.business_rounded : Icons.home_rounded, color: context.primary),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${a.label} · ${t.pyeong('${a.sizePyeong}')}', style: context.text.titleSmall),
                          Text('${a.roadAddress} ${a.detail}', style: context.text.bodySmall),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ),
            ]),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: t.addressAdd, onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AddressFormScreen()))),
      ),
    );
  }
}

/// Add / edit. District comes from the service-area list; size is required (studio rule).
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.existing});
  final Address? existing;
  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _road = TextEditingController(text: widget.existing?.roadAddress ?? '');
  late final _detail = TextEditingController(text: widget.existing?.detail ?? '');
  late final _size = TextEditingController(text: widget.existing?.sizePyeong.toString() ?? '');
  late String _kind = widget.existing?.kind ?? 'home';
  late String? _district = widget.existing?.districtCode;
  bool _busy = false;

  bool get _valid {
    final size = int.tryParse(_size.text);
    return _label.text.trim().isNotEmpty && _road.text.trim().isNotEmpty && _district != null && size != null && size >= 1 && size <= 500;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final saved = await context.appRead.saveAddress({
        'kind': _kind,
        'label': _label.text.trim(),
        'road_address': _road.text.trim(),
        'detail': _detail.text.trim(),
        'district_code': _district,
        'size_pyeong': int.parse(_size.text),
      }, id: widget.existing?.id);
      if (!mounted) return;
      showToast(context, context.t.addressSaved);
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    try {
      await context.appRead.deleteAddress(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  @override
  void dispose() {
    for (final c in [_label, _road, _detail, _size]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = context.lang;
    InputDecoration deco(String label, [String? hint, String? helper]) => InputDecoration(labelText: label, hintText: hint, helperText: helper);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? t.addressAdd : t.edit),
        actions: [if (widget.existing != null) IconButton(tooltip: t.delete, icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete)],
      ),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [ButtonSegment(value: 'home', label: Text(t.addressHome), icon: const Icon(Icons.home_rounded)), ButtonSegment(value: 'office', label: Text(t.addressOffice), icon: const Icon(Icons.business_rounded))],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() => _kind = s.first),
        ),
        const SizedBox(height: Space.lg),
        TextField(controller: _label, maxLength: 40, decoration: deco(t.addressLabel, t.addressLabelHint).copyWith(counterText: ''), onChanged: (_) => setState(() {})),
        const SizedBox(height: Space.md),
        DropdownButtonFormField<String>(
          initialValue: _district,
          decoration: deco(t.addressDistrict),
          items: [for (final d in seoulDistricts) DropdownMenuItem(value: d.code, child: Text(d.name(lang)))],
          onChanged: (v) => setState(() => _district = v),
        ),
        const SizedBox(height: Space.md),
        // shortcut: typed road address; swap for the Kakao postcode / juso.go.kr search widget once API keys exist.
        TextField(controller: _road, maxLength: 200, decoration: deco(t.addressRoad).copyWith(counterText: ''), onChanged: (_) => setState(() {})),
        const SizedBox(height: Space.md),
        TextField(controller: _detail, maxLength: 200, decoration: deco(t.addressDetail).copyWith(counterText: '')),
        const SizedBox(height: Space.md),
        TextField(
          controller: _size,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          decoration: deco(t.addressSize, null, t.addressSizeHelp),
          onChanged: (_) => setState(() {}),
        ),
      ]),
      bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: t.save, busy: _busy, onPressed: _valid ? _save : null)),
    );
  }
}
