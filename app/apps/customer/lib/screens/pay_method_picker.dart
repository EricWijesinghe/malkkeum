import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// What the customer chose: a saved one-tap method, or a payment channel opened per payment.
sealed class PayChoice {
  const PayChoice();
}

final class SavedChoice extends PayChoice {
  const SavedChoice(this.methodId);
  final String methodId;
}

final class ChannelChoice extends PayChoice {
  const ChannelChoice(this.channel);
  final PayChannel channel;
}

/// Every payment method in one picker: saved one-tap methods first, then the full channel grid.
/// Billing channels register once (then they behave like saved methods); checkout channels
/// are picked per payment and open the PG window on pay.
class PayMethodPicker extends StatefulWidget {
  const PayMethodPicker({super.key, required this.onChoose, this.selectedSavedId, this.selectedChannel});

  final ValueChanged<PayChoice> onChoose;
  final String? selectedSavedId;
  final String? selectedChannel;

  @override
  State<PayMethodPicker> createState() => _PayMethodPickerState();
}

class _PayMethodPickerState extends State<PayMethodPicker> {
  late Future<List<PayChannel>> _channels;
  String? _registering;

  @override
  void initState() {
    super.initState();
    _channels = fetchPayChannels(context.api);
  }

  void _reload() => setState(() => _channels = fetchPayChannels(context.api));

  /// A billing channel already saved picks that method; otherwise it is registered first.
  Future<void> _billing(PayChannel ch) async {
    final app = context.appRead;
    final existing = app.methods.where((m) => m.provider == ch.code).firstOrNull;
    if (existing != null) {
      widget.onChoose(SavedChoice(existing.id));
      return;
    }
    setState(() => _registering = ch.code);
    try {
      final m = await app.addMethod(ch.code, context.t.payMethod(ch.code));
      if (mounted) widget.onChoose(SavedChoice(m.id));
    } catch (e) {
      if (mounted) showToast(context, context.t.payError(e));
    } finally {
      if (mounted) setState(() => _registering = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final app = context.app;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (app.methods.isNotEmpty) ...[
          Text(t.apPaySavedTitle, style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          for (final m in app.methods)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: OptionCard(
                leading: PayBrandBadge(code: m.provider, height: 32),
                title: m.displayName,
                selected: m.id == widget.selectedSavedId,
                onTap: () => widget.onChoose(SavedChoice(m.id)),
              ),
            ),
          const SizedBox(height: Space.sm),
        ],
        Text(t.apPayMoreTitle, style: context.text.titleSmall),
        const SizedBox(height: Space.xxs),
        Text(t.apPayCheckoutHint, style: context.text.labelSmall?.copyWith(color: context.colors.inkMuted)),
        const SizedBox(height: Space.xs),
        FutureBuilder<List<PayChannel>>(
          future: _channels,
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorRetry(message: context.t.errorGeneric, retryLabel: context.t.retry, onRetry: _reload);
            }
            final channels = snap.data;
            if (channels == null) return const Padding(padding: EdgeInsets.all(Space.lg), child: Center(child: CircularProgressIndicator()));
            return LayoutBuilder(builder: (context, c) {
              final width = (c.maxWidth - Space.xs) / 2;
              return Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
                for (final ch in channels)
                  SizedBox(
                    width: width,
                    child: PayChannelTile(
                      code: ch.code,
                      label: t.payMethod(ch.code),
                      selected: !ch.isBilling && ch.code == widget.selectedChannel,
                      busy: _registering == ch.code,
                      onTap: _registering != null ? null : () => ch.isBilling ? _billing(ch) : widget.onChoose(ChannelChoice(ch)),
                    ),
                  ),
              ]);
            });
          },
        ),
      ]),
    );
  }
}

/// One method in the grid: brand badge + label. 48px+ target, selection ring, busy spinner.
class PayChannelTile extends StatelessWidget {
  const PayChannelTile({super.key, required this.code, required this.label, required this.onTap, this.selected = false, this.busy = false});

  final String code;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.tile),
            side: BorderSide(color: selected ? context.primary : context.colors.line, width: selected ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.tile),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
                child: Row(children: [
                  PayBrandBadge(code: code, height: 32),
                  const SizedBox(width: Space.xs),
                  Expanded(child: Text(label, style: context.text.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  if (busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
