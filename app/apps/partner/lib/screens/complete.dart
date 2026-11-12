import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui/ui.dart';

import '../outbox.dart';
import '../state.dart';

/// Before/after photos + 4-item checklist. "Complete" unlocks when all are done.
/// Photos and the completion are kept on disk first, so a bad signal queues them instead of losing them.
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
  final _before = <QueuedPhoto>[];
  final _after = <QueuedPhoto>[];
  final _checks = List<bool>.filled(4, false);
  final _sending = <QueuedPhoto>{};
  final _failed = <QueuedPhoto>{};
  late final CompletionOutbox _box;
  bool _busy = false;

  /// Set once the job is completed or queued, so leaving the screen does not keep a draft.
  bool _finished = false;

  bool get _ready =>
      _before.isNotEmpty && _after.isNotEmpty && _checks.every((c) => c);

  @override
  void initState() {
    super.initState();
    _box = context.proRead.outbox;
    _restore().ignore();
  }

  @override
  void dispose() {
    if (!_finished) _saveDraft().ignore();
    super.dispose();
  }

  /// Reloads a draft (or a queued completion) left by an earlier visit.
  Future<void> _restore() async {
    final draft = await _box.find(widget.bookingId);
    if (draft == null || !mounted) return;
    setState(() {
      _before.addAll(draft.before);
      _after.addAll(draft.after);
      for (var i = 0; i < _checks.length; i++) {
        _checks[i] = draft.checklist[i];
      }
    });
    for (final p in draft.photos) {
      if (p.url == null) _upload(p).ignore();
    }
  }

  QueuedCompletion _entry({bool ready = false}) => QueuedCompletion(
    basePath: widget.basePath,
    bookingId: widget.bookingId,
    before: _before,
    after: _after,
    checklist: _checks,
    ready: ready,
  );

  Future<void> _saveDraft() async {
    final e = _entry();
    if (e.isEmpty) {
      await _box.remove(e);
    } else {
      await _box.save(e);
    }
  }

  Future<void> _add(List<QueuedPhoto> into) async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 2048,
      imageQuality: 85,
      limit: 10,
    );
    if (files.isEmpty || !mounted) return;
    for (final f in files) {
      final p = await _box.stash(await f.readAsBytes(), widget.bookingId);
      if (!mounted) return;
      setState(() => into.add(p));
      await _upload(p);
    }
  }

  /// One photo at a time. A failure keeps the photo on disk, shown with a retry tile.
  Future<void> _upload(QueuedPhoto p) async {
    setState(() {
      _sending.add(p);
      _failed.remove(p);
    });
    try {
      await _box.uploadPhoto(context.api, p);
      await _saveDraft();
    } catch (e) {
      if (mounted) {
        setState(() => _failed.add(p));
        if (e is! ApiException || !e.isNetwork) {
          showToast(context, context.t.error(e));
        }
      }
    } finally {
      if (mounted) setState(() => _sending.remove(p));
    }
  }

  Future<void> _remove(List<QueuedPhoto> list, QueuedPhoto p) async {
    setState(() => list.remove(p));
    await _box.dropPhoto(p);
    await _saveDraft();
  }

  Future<void> _complete() async {
    final entry = _entry(ready: true);
    final api = context.api;
    setState(() => _busy = true);
    try {
      await _box.save(entry);
      final r = await _box.send(api, entry);
      _finished = true;
      if (!mounted) return;
      if (!widget.isMember) {
        context.proRead
          ..jobsChanged()
          ..loadProfile().ignore();
      }
      await _success(r);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isNetwork) {
        _finished = true;
        showToast(context, context.t.pOfflineSaved);
        Navigator.of(context).pop();
      } else {
        showToast(context, context.t.error(e));
      }
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
    final waiting = [..._before, ..._after].where((p) => p.url == null).length;
    return Scaffold(
      appBar: AppBar(title: Text(t.pComplete)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          _photos(t.pBeforePhotos, _before, ServiceHues.kitchen),
          const SizedBox(height: Space.lg),
          _photos(t.pAfterPhotos, _after, ServiceHues.moveOut),
          if (waiting > 0)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(t.pPhotoWaiting, style: context.text.labelSmall),
            ),
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
                    onChanged: (v) {
                      setState(() => _checks[i] = v ?? false);
                      _saveDraft().ignore();
                    },
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
          onPressed: _ready && _sending.isEmpty && !_busy ? _complete : null,
        ),
      ),
    );
  }

  Widget _photos(String title, List<QueuedPhoto> list, ServiceHue hue) {
    final uploaded = list.where((p) => p.url != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('$title (${list.length})'),
        if (_sending.any(list.contains))
          Text(
            context.t.pUploadedCount('${list.length}', '$uploaded'),
            style: context.text.labelSmall,
          ),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _add(list),
                child: Container(
                  width: 96,
                  decoration: BoxDecoration(
                    color: context.colors.tintOf(hue),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // The label below names the action, so the art is decorative.
                      const ExcludeSemantics(
                        child: Icon3D('p_camera', size: 40),
                      ),
                      Text(context.t.pAddPhoto, style: context.text.labelSmall),
                    ],
                  ),
                ),
              ),
              for (final p in list) _tile(p, list),
            ],
          ),
        ),
      ],
    );
  }

  /// Local preview (works offline). Overlays show upload progress, a retry for failed uploads, and removal.
  Widget _tile(QueuedPhoto p, List<QueuedPhoto> list) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(p.file),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          if (_sending.contains(p))
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_failed.contains(p))
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: IconButton.filled(
                    tooltip: t.pPhotoRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => _upload(p),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: IconButton.filledTonal(
              tooltip: t.delete,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => _remove(list, p),
            ),
          ),
        ],
      ),
    );
  }
}
