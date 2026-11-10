import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Store-review demo login: one phone number with a fixed 6-digit code for App Review and
/// Google Play reviewers, who cannot receive Korean SMS. Turns itself off after 14 days.
class ReviewAccountCard extends StatefulWidget {
  const ReviewAccountCard({
    super.key,
    required this.current,
    required this.onChanged,
  });
  final Json? current;
  final VoidCallback onChanged;

  @override
  State<ReviewAccountCard> createState() => _ReviewAccountCardState();
}

class _ReviewAccountCardState extends State<ReviewAccountCard> {
  late final _phone = TextEditingController(
    text: widget.current?['phone'] as String? ?? '',
  );
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showToast(context, context.t.cSetupSaved);
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) {
        showToast(
          context,
          e.status == 400 ? context.t.cInvalidValue : context.t.error(e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final until = DateTime.tryParse(
      widget.current?['expires_at'] as String? ?? '',
    )?.toLocal();
    final active = until != null && until.isAfter(DateTime.now());
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            Space.lg,
            0,
            Space.lg,
            Space.lg,
          ),
          leading: Icon(
            Icons.verified_user_rounded,
            color: active ? context.primary : null,
          ),
          title: Text(t.cReviewTitle, style: context.text.titleMedium),
          subtitle: active
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tag(
                      label: t.cReviewActiveUntil(
                        DateFormat.yMd(context.lang).format(until),
                      ),
                      hue: StatusHues.assigned,
                    ),
                  ),
                )
              : null,
          children: [
            Text(t.cReviewHint, style: context.text.bodyMedium),
            const SizedBox(height: Space.md),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: t.cReviewPhone,
                hintText: '010-0000-0000',
              ),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: t.cReviewCode),
            ),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => context.api.put('/admin/setup/review', {
                            'phone': _phone.text,
                            'code': _code.text,
                            'days': 14,
                          }),
                        ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(t.cReviewEnable),
                ),
                if (active)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => context.api.delete('/admin/setup/review'),
                          ),
                    child: Text(t.cSetupClear),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
