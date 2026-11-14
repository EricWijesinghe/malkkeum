import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'catalog_counts.dart';
import 'catalog_groups_model.dart';

/// Home tiles: order, titles, picture, member services and the move-chooser questions.
class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final _view = GlobalKey<AsyncViewState<_GroupsData>>();

  Future<_GroupsData> _load() async {
    final api = context.api;
    final groups =
        (await api.get('/admin/service-groups') as Json)['groups'] as List;
    final services = (await api.get('/admin/services') as List).cast<Json>();
    return _GroupsData(groups.cast<Json>(), services);
  }

  Future<void> _edit(_GroupsData data, Json group) async {
    final t = context.t;
    final body = await showDialog<Json>(
      context: context,
      builder: (_) => _GroupDialog(group: group, data: data),
    );
    if (body == null || !mounted) return;
    try {
      await context.api.put('/admin/service-groups/${group['code']}', body);
      if (mounted) showToast(context, t.cgGroupSaved);
      await _view.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) {
        showToast(
          context,
          groupServerMessage(t, e.code) ?? t.cgGroupErrUnknown,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<_GroupsData>(
      key: _view,
      load: _load,
      builder: (context, data, _) => ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text(t.cgGroupsHelp),
          const SizedBox(height: Space.md),
          for (final g in data.groups)
            Card(
              elevation: 0,
              child: ListTile(
                title: Text((g['title'] as Json)['ko'] as String),
                subtitle: Text(_info(context, g)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tag(
                      label: g['active'] == true
                          ? t.cgGroupShown
                          : t.cgGroupHidden,
                      hue: g['active'] == true
                          ? StatusHues.confirmed
                          : StatusHues.cancelled,
                    ),
                    const Icon(Icons.edit_outlined),
                  ],
                ),
                onTap: context.console.isAdmin
                    ? () => _edit(data, g)
                    : () => showToast(context, t.cAdminOnly),
              ),
            ),
        ],
      ),
    );
  }

  String _info(BuildContext context, Json g) {
    final t = context.t;
    final chooser = switch (g['chooser']) {
      'move' => t.cgChooserMove,
      'direct' => t.cgChooserDirect,
      _ => t.cgChooserList,
    };
    return t.cgGroupRowInfo(chooser, '${(g['services'] as List).length}');
  }
}

class _GroupsData {
  const _GroupsData(this.groups, this.services);

  final List<Json> groups;
  final List<Json> services;
}

/// Edit dialog for one group. Returns the PUT body, or null when cancelled.
class _GroupDialog extends StatefulWidget {
  const _GroupDialog({required this.group, required this.data});

  final Json group;
  final _GroupsData data;

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  late final GroupDraft _d = GroupDraft.from(widget.group);
  late final TextEditingController _ko = TextEditingController(
    text: _d.titleKo,
  );
  late final TextEditingController _en = TextEditingController(
    text: _d.titleEn,
  );
  late final TextEditingController _order = TextEditingController(
    text: '${_d.order}',
  );
  String? _error;

  @override
  void dispose() {
    _ko.dispose();
    _en.dispose();
    _order.dispose();
    super.dispose();
  }

  void _save(T t) {
    _d
      ..titleKo = _ko.text
      ..titleEn = _en.text
      ..order = int.tryParse(_order.text.trim()) ?? -1;
    final problem = _d.problem(t);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(_d.toBody());
  }

  String _name(Json s) {
    final t = context.t;
    final name = (s['content'] as Json?)?['name'];
    return name is String && name.isNotEmpty
        ? name
        : t.service(s['code'] as String);
  }

  String? _otherGroup(String code) {
    for (final g in widget.data.groups) {
      if (g['code'] == _d.code) continue;
      if ((g['services'] as List).contains(code)) {
        return (g['title'] as Json)['ko'] as String;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(_d.titleKo.isEmpty ? t.cgTabGroups : _d.titleKo),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _text(_ko, t.cgGroupTitleKo),
              const SizedBox(height: 8),
              _text(_en, t.cgGroupTitleEn),
              const SizedBox(height: 8),
              _text(_order, t.cgGroupOrder, number: true),
              const SizedBox(height: 8),
              _iconPicker(t),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.cgGroupShown),
                value: _d.active,
                onChanged: (v) => setState(() => _d.active = v),
              ),
              const Divider(height: 24),
              _chooserPicker(t),
              const Divider(height: 24),
              Text(
                t.cgGroupMembers,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(t.cgGroupMembersHelp),
              for (final s in widget.data.services) _memberRow(s, t),
              if (_d.chooser == 'move') ..._moveFields(t),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(onPressed: () => _save(t), child: Text(t.save)),
      ],
    );
  }

  Widget _text(TextEditingController c, String label, {bool number = false}) =>
      TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : null,
        inputFormatters: number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(labelText: label, isDense: true),
      );

  Widget _iconPicker(T t) {
    final ids = {
      for (final id in Icon3DRegistry.specs.keys)
        if (id.startsWith('svc_')) id,
      _d.icon,
    }.toList();
    return DropdownButtonFormField<String>(
      initialValue: _d.icon,
      decoration: InputDecoration(labelText: t.cgGroupIcon, isDense: true),
      items: [
        for (final id in ids)
          DropdownMenuItem(value: id, child: Icon3D(id, size: 28)),
      ],
      onChanged: (v) => setState(() => _d.icon = v ?? _d.icon),
    );
  }

  Widget _chooserPicker(T t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(t.cgGroupChooser, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        children: [
          for (final c in groupChoosers)
            ChoiceChip(
              label: Text(_chooserLabel(t, c)),
              selected: _d.chooser == c,
              onSelected: (_) => setState(() => _d.chooser = c),
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text(_chooserHelp(t, _d.chooser)),
    ],
  );

  String _chooserLabel(T t, String c) => switch (c) {
    'move' => t.cgChooserMove,
    'direct' => t.cgChooserDirect,
    _ => t.cgChooserList,
  };

  String _chooserHelp(T t, String c) => switch (c) {
    'move' => t.cgChooserMoveHelp,
    'direct' => t.cgChooserDirectHelp,
    _ => t.cgChooserListHelp,
  };

  Widget _memberRow(Json s, T t) {
    final code = s['code'] as String;
    final picked = _d.members.contains(code);
    final other = picked ? null : _otherGroup(code);
    final index = _d.members.indexOf(code);
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: picked,
      title: Text(_name(s)),
      subtitle: other == null ? null : Text(t.cgMemberOtherGroup(other)),
      secondary: picked
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: t.cntMoveUp,
                  onPressed: index <= 0 ? null : () => _swap(index, index - 1),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: t.cntMoveDown,
                  onPressed: index >= _d.members.length - 1
                      ? null
                      : () => _swap(index, index + 1),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
            )
          : null,
      onChanged: other != null
          ? null
          : (v) => setState(() {
              if (v == true) {
                _d.members.add(code);
              } else {
                _d.members.remove(code);
                if (_d.newService == code) _d.newService = null;
                if (_d.oldService == code) _d.oldService = null;
              }
            }),
    );
  }

  void _swap(int i, int j) => setState(() => swapAt(_d.members, i, j));

  List<Widget> _moveFields(T t) {
    final picks = _d.members;
    return [
      const SizedBox(height: 12),
      _servicePick(
        t.cgMoveNewService,
        _d.newService,
        picks,
        (v) => _d.newService = v,
      ),
      const SizedBox(height: 8),
      _servicePick(
        t.cgMoveOldService,
        _d.oldService,
        picks,
        (v) => _d.oldService = v,
      ),
      const SizedBox(height: 8),
      Text(t.cgMoveHomeTypes),
      Wrap(
        spacing: 8,
        children: [
          for (final h in groupHomeTypes)
            FilterChip(
              label: Text(_homeLabel(t, h)),
              selected: _d.homeTypes.contains(h),
              onSelected: (v) => setState(() {
                if (v) {
                  _d.homeTypes.add(h);
                } else {
                  _d.homeTypes.remove(h);
                }
              }),
            ),
        ],
      ),
    ];
  }

  String _homeLabel(T t, String h) => switch (h) {
    'one_two_room' => t.cgHomeOneTwo,
    'apartment' => t.cgHomeApartment,
    _ => t.cgHomeVilla,
  };

  Widget _servicePick(
    String label,
    String? value,
    List<String> options,
    void Function(String?) set,
  ) {
    final names = {
      for (final s in widget.data.services) s['code'] as String: _name(s),
    };
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        for (final code in options)
          DropdownMenuItem(value: code, child: Text(names[code] ?? code)),
      ],
      onChanged: (v) => setState(() => set(v)),
    );
  }
}
