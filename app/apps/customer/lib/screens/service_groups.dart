import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'move_chooser.dart';
import 'service.dart';

/// Where a home group tile leads: `move` asks its questions, `direct` opens its one service,
/// `list` shows the member picker. A direct group with no member in the catalogue shows the picker.
void openServiceGroup(
  BuildContext context,
  ServiceGroup group,
  List<Service> services,
) {
  final members = groupMembers(group, services);
  final Widget page = switch (group.chooser) {
    'move' => const MoveChooserScreen(),
    'direct' when members.isNotEmpty => ServiceScreen(service: members.first),
    _ => ServiceGroupScreen(group: group),
  };
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => page));
}

/// Member services of [group] in its own order; services not in the catalogue are left out.
List<Service> groupMembers(ServiceGroup group, List<Service> services) => [
  for (final code in group.services)
    for (final s in services)
      if (s.code == code) s,
];

/// Member picker for a `list` group (CR-7.4): one row per service, each opening its own screen.
class ServiceGroupScreen extends StatelessWidget {
  const ServiceGroupScreen({super.key, required this.group});
  final ServiceGroup group;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final services = context.app.services;
    final members = groupMembers(group, services);
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        title: Text(group.titleFor(lang)),
      ),
      body: ListView(
        children: [
          for (final s in members)
            ListTile(
              leading: Icon3D(
                Icon3DRegistry.serviceId(s.code),
                size: 44,
              ),
              title: Text(t.service(s.code)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ServiceScreen(service: s),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
