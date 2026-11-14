import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'flow_widgets.dart';
import 'quote_flow.dart';

/// Entry for 이사·입주 청소 (CR-3) and whole-home (CR-4). Q1 신축 → move-in, 구축 → move-out (only
/// without a [service]); Q2 picks the home type, each row marked 예상 견적 (an estimate, never a fixed price).
class MoveChooserScreen extends StatefulWidget {
  const MoveChooserScreen({super.key, this.service});

  /// Whole-home passes its own service and skips Q1.
  final Service? service;

  @override
  State<MoveChooserScreen> createState() => _MoveChooserScreenState();
}

class _MoveChooserScreenState extends State<MoveChooserScreen> {
  bool? _newBuild;

  Service? _quoteService(AppState app) =>
      widget.service ??
      switch (_newBuild) {
        true => app.service('move_in'),
        false => app.service('move_out'),
        null => null,
      };

  void _open(MoveHome home) {
    final svc = _quoteService(context.appRead);
    if (svc == null) {
      showToast(context, context.t.error(StateError('service missing')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteFlowScreen(service: svc, home: home),
      ),
    );
  }

  static String _homeLabel(T t, MoveHome h) => switch (h) {
    MoveHome.oneTwoRoom => t.hgHomeOneTwo,
    MoveHome.apartment => t.hgHomeApartment,
    MoveHome.villaHouse => t.hgHomeVilla,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final askBuild = widget.service == null;
    final askSize = !askBuild || _newBuild != null;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(backgroundColor: context.colors.surface),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FlowTitle(askBuild ? t.hgMoveQuestion : t.hgSizeQuestion),
            if (askBuild)
              FlowSection(
                children: [
                  RadioRow(
                    title: t.hgNewBuild,
                    subtitle: t.hgNewBuildBody,
                    selected: _newBuild == true,
                    onTap: () => setState(() => _newBuild = true),
                  ),
                  RadioRow(
                    title: t.hgOldBuild,
                    subtitle: t.hgOldBuildBody,
                    selected: _newBuild == false,
                    onTap: () => setState(() => _newBuild = false),
                  ),
                ],
              ),
            if (askSize) ...[
              const FlowBand(),
              FlowSection(
                title: askBuild ? t.hgSizeQuestion : null,
                children: [
                  for (final h in MoveHome.values)
                    ListTile(
                      title: Text(_homeLabel(t, h)),
                      subtitle: Text(t.hgEstimateOnly),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(h),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(Space.gutter),
                child: Text(
                  t.hgEstimateNote,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
