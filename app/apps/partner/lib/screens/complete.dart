import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Before/after photos + 4-item checklist. "Complete" unlocks only when all are done.
class CompleteScreen extends StatefulWidget {
  const CompleteScreen({
    super.key,
    required this.bookingId,
    required this.isQuote,
    this.basePath = '/partner',
  });
  final String bookingId;
  final bool isQuote;

  /// `/partner` for the team owner, `/member` for a team member (no payout shown).
  final String basePath;
  bool get isMember => basePath == '/member';
  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> {
  final _before = <String>[];
  final _after = <String>[];
  final _checks = List<bool>.filled(4, false);
  bool _uploading = false;
  bool _busy = false;

  bool get _ready =>
      _before.isNotEmpty && _after.isNotEmpty && _checks.every((c) => c);

  Future<void> _add(List<String> into) async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 2048,
      imageQuality: 85,
      limit: 10,
    );
    if (files.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    try {
      for (final f in files) {
        final url = await context.api.upload(await f.readAsBytes(), f.name);
        if (!mounted) return;
        setState(() => into.add(url));
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      final r =
          await context.api.post(
                '${widget.basePath}/jobs/${widget.bookingId}/complete',
                {
                  'before_photos': _before,
                  'after_photos': _after,
                  'checklist': _checks,
                },
              )
              as Json;
      if (!mounted) return;
      if (!widget.isMember) {
        context.proRead
          ..jobsChanged()
          ..loadProfile().ignore();
      }
      await _success(r);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _success(Json r) async {
    final t = context.t;
    final date = r['payout_date'] as String?;
    await showAppSheet<void>(
      context,
      title: '',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SuccessMark(size: 88, semanticLabel: t.pCompleted),
            Text(t.pCompleted, style: ctx.text.headlineSmall),
            const SizedBox(height: Space.xs),
            if (!widget.isMember)
              Text(
                date == null
                    ? t.pPayoutWaiting
                    : t.pPayoutOn(
                        dateLabel(DateTime.parse(date), ctx.lang),
                        ctx.won((r['net'] as num).toInt()),
                      ),
                style: ctx.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.ok),
            ),
          ],
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final checks = [t.pCheck1, t.pCheck2, t.pCheck3, t.pCheck4];
    return Scaffold(
      appBar: AppBar(title: Text(t.pComplete)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          _photos(t.pBeforePhotos, _before, ServiceHues.kitchen),
          const SizedBox(height: Space.lg),
          _photos(t.pAfterPhotos, _after, ServiceHues.moveOut),
          const SizedBox(height: Space.lg),
          SectionTitle(t.pChecklist),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < checks.length; i++)
                  CheckboxListTile(
                    value: _checks[i],
                    title: Text(checks[i]),
                    onChanged: (v) => setState(() => _checks[i] = v ?? false),
                  ),
              ],
            ),
          ),
          if (!_ready)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(t.pCompleteNeed, style: context.text.labelSmall),
            ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: t.pCompleteCta,
          busy: _busy,
          color: context.colors.fresh,
          onPressed: _ready && !_uploading ? _complete : null,
        ),
      ),
    );
  }

  Widget _photos(String title, List<String> urls, ServiceHue hue) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionTitle('$title (${urls.length})'),
      SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _uploading ? null : () => _add(urls),
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  color: context.colors.tintOf(hue),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: hue.tone),
                          Text(
                            context.t.pAddPhoto,
                            style: context.text.labelSmall,
                          ),
                        ],
                      ),
              ),
            ),
            for (final u in urls)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        u,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton.filledTonal(
                        tooltip: context.t.delete,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => urls.remove(u)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
