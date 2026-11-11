import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

const _petKinds = ['dog', 'cat', 'bird', 'fish', 'other'];
const _maxPets = 5;

class _PetRow {
  _PetRow(this.kind, int count) : count = TextEditingController(text: '$count');
  String kind;
  final TextEditingController count;
}

/// Household profile for an address: pets, allergies, preferred products, parking, floor, elevator, notes.
/// Reports the whole profile through [onChanged] on every edit; the parent sends it with the address.
class HouseholdEditor extends StatefulWidget {
  const HouseholdEditor({super.key, required this.initial, required this.onChanged});

  final Json initial;
  final ValueChanged<Json> onChanged;

  @override
  State<HouseholdEditor> createState() => _HouseholdEditorState();
}

class _HouseholdEditorState extends State<HouseholdEditor> {
  late final List<_PetRow> _pets = [
    for (final p in (widget.initial['pets'] as List? ?? const []).cast<Json>()) _PetRow(p['kind'] as String, (p['count'] as num).toInt()),
  ];
  late final _allergies = TextEditingController(text: widget.initial['allergies'] as String? ?? '');
  late final _preferred = TextEditingController(text: widget.initial['preferred_products'] as String? ?? '');
  late final _parking = TextEditingController(text: widget.initial['parking'] as String? ?? '');
  late final _notes = TextEditingController(text: widget.initial['notes'] as String? ?? '');
  late final _floor = TextEditingController(text: widget.initial['floor'] == null ? '' : '${widget.initial['floor']}');
  late bool _elevator = widget.initial['elevator'] == true;

  @override
  void dispose() {
    for (final p in _pets) {
      p.count.dispose();
    }
    for (final c in [_allergies, _preferred, _parking, _notes, _floor]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final pets = [
      for (final p in _pets)
        if ((int.tryParse(p.count.text) ?? 0) > 0) {'kind': p.kind, 'count': int.parse(p.count.text)},
    ];
    final floor = int.tryParse(_floor.text);
    widget.onChanged({
      'pets': pets,
      'allergies': _allergies.text.trim(),
      'preferred_products': _preferred.text.trim(),
      'parking': _parking.text.trim(),
      'notes': _notes.text.trim(),
      'floor': floor,
      'elevator': _elevator,
    });
  }

  String _petLabel(BuildContext context, String kind) {
    final t = context.t;
    return switch (kind) {
      'dog' => t.pPetDog,
      'cat' => t.pPetCat,
      'bird' => t.pPetBird,
      'fish' => t.pPetFish,
      _ => t.pPetOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final fieldGap = const SizedBox(height: Space.sm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.hhTitle, style: context.text.titleSmall),
        Text(t.hhHint, style: context.text.bodySmall),
        const SizedBox(height: Space.sm),
        for (var i = 0; i < _pets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Row(children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _pets[i].kind,
                  items: [for (final k in _petKinds) DropdownMenuItem(value: k, child: Text(_petLabel(context, k)))],
                  onChanged: (v) => setState(() {
                    _pets[i].kind = v ?? _pets[i].kind;
                    _emit();
                  }),
                ),
              ),
              const SizedBox(width: Space.sm),
              SizedBox(
                width: 84,
                child: TextField(
                  controller: _pets[i].count,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                  decoration: InputDecoration(labelText: t.hhPetCount),
                  onChanged: (_) => _emit(),
                ),
              ),
              IconButton(
                tooltip: t.delete,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: () => setState(() {
                  _pets.removeAt(i).count.dispose();
                  _emit();
                }),
              ),
            ]),
          ),
        if (_pets.length < _maxPets)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(t.hhAddPet),
              onPressed: () => setState(() {
                _pets.add(_PetRow(_petKinds.first, 1));
                _emit();
              }),
            ),
          ),
        fieldGap,
        TextField(controller: _allergies, maxLength: 300, decoration: InputDecoration(labelText: t.pAllergies), onChanged: (_) => _emit()),
        fieldGap,
        TextField(controller: _preferred, maxLength: 300, decoration: InputDecoration(labelText: t.pPreferredProducts), onChanged: (_) => _emit()),
        fieldGap,
        TextField(controller: _parking, maxLength: 300, decoration: InputDecoration(labelText: t.pParking), onChanged: (_) => _emit()),
        fieldGap,
        TextField(
          controller: _floor,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}$'))],
          decoration: InputDecoration(labelText: t.hhFloorLabel),
          onChanged: (_) => _emit(),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.hhElevator),
          value: _elevator,
          onChanged: (v) => setState(() {
            _elevator = v;
            _emit();
          }),
        ),
        fieldGap,
        TextField(controller: _notes, maxLength: 300, maxLines: 3, decoration: InputDecoration(labelText: t.hhNotes), onChanged: (_) => _emit()),
      ],
    );
  }
}
