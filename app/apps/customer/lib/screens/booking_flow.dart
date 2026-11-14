import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'addresses.dart';
import 'booking_detail.dart';
import 'chat.dart';
import 'checkout.dart';
import 'flow_widgets.dart';
import 'more.dart';
import 'service_scope.dart';

export 'ac_addon_banner.dart';
export 'checkout.dart';
export 'flow_widgets.dart';

part 'booking_done.dart';

const _maxDaysAhead = 60;
const _standardSlots = [8, 9, 13, 14];
const _quoteSlots = [8, 13];
const _freeCancelDays = 2;
const _confirmSize = 160.0;
const _minConfirmSize = 112.0; // SuccessMark's own default
const _toolStagger = Duration(milliseconds: 30);
const _pillShare = 0.4;
const _glyphKickDelay = Duration(milliseconds: 700);
const _managerAvatar = 72.0;

/// Slug of the console tip behind the schedule step's "어떤 교육을 받나요?" link.
const trainingTipSlug = 'manager-training';

/// Last free-cancel day for a visit on [visit], or null when that day is already past
/// (a booking inside the window), so checkout never promises a deadline that has gone.
DateTime? freeCancelDeadline(DateTime visit, DateTime now) {
  final day = DateTime(
    visit.year,
    visit.month,
    visit.day,
  ).subtract(const Duration(days: _freeCancelDays));
  return day.isBefore(DateTime(now.year, now.month, now.day)) ? null : day;
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime get _firstDay =>
    DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));

/// Saved addresses as radio rows ("우리집 · 8평 수정") plus "+ 주소 추가" (design p09).
/// An address over the service's size limit is not selectable: a toast offers a consultation.
class AddressRadioList extends StatelessWidget {
  const AddressRadioList({
    super.key,
    required this.draft,
    required this.onChanged,
  });
  final BookingDraft draft;
  final VoidCallback onChanged;

  bool _fits(Address a) =>
      draft.service.maxPyeong == null ||
      a.sizePyeong <= draft.service.maxPyeong!;

  void _tooBig(BuildContext context, Address a) {
    final t = context.t;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // With an action a SnackBar would stay up forever by default.
          persist: false,
          content: Text(
            t.dfStudioToast(
              t.service(draft.service.code),
              '${draft.service.maxPyeong}',
              a.label,
              '${a.sizePyeong}',
            ),
          ),
          action: SnackBarAction(
            label: t.consultCta,
            onPressed: () => openTopicChat(context, draft.service.code),
          ),
        ),
      );
  }

  Future<void> _edit(BuildContext context, Address a) async {
    final app = context.appRead;
    await showAddressForm(context, existing: a);
    await app.loadAddresses();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final app = context.app;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in app.addresses)
          RadioRow(
            title: a.label,
            subtitle:
                '${a.roadAddress} ${a.detail} · ${t.pyeong('${a.sizePyeong}')}',
            subtitleTrailing: InkWell(
              onTap: () => _edit(context, a),
              child: Text(
                t.dfEdit,
                style: context.text.bodyMedium?.copyWith(
                  color: context.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            selected: draft.address?.id == a.id,
            onTap: () {
              if (!_fits(a)) return _tooBig(context, a);
              draft.address = a;
              onChanged();
            },
          ),
        const SizedBox(height: Space.lg),
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: Text(t.addressAdd),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size(0, 48),
            ),
            onPressed: () async {
              final added = await showAddressForm(context);
              if (added == null || !context.mounted) return;
              if (_fits(added)) {
                draft.address = added;
              } else {
                _tooBig(context, added);
              }
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}

/// Pick a saved address, or add one (design p09). Enforces the studio size rule.
class AddressPickScreen extends StatefulWidget {
  const AddressPickScreen({super.key, required this.draft, this.onPicked});
  final BookingDraft draft;
  final void Function(BuildContext context)? onPicked;
  @override
  State<AddressPickScreen> createState() => _AddressPickScreenState();
}

class _AddressPickScreenState extends State<AddressPickScreen> {
  BookingDraft get d => widget.draft;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final max = d.service.maxPyeong;
    d.address ??= context.app.addresses
        .where((a) => max == null || a.sizePyeong <= max)
        .firstOrNull;
    // Own messenger: the size toast leaves with this screen instead of following the user back.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(backgroundColor: context.colors.surface),
        body: ListView(
          children: [
            FlowTitle(t.dfAddressTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: AddressRadioList(
                draft: d,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          child: PrimaryButton(
            label: t.next,
            onPressed: d.address == null
                ? null
                : () => widget.onPicked != null
                      ? widget.onPicked!(context)
                      : Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ScheduleScreen(draft: d),
                          ),
                        ),
          ),
        ),
      ),
    );
  }
}

/// Opens (or reuses) a general consultation thread and shows it.
Future<void> openTopicChat(
  BuildContext context,
  String topic, {
  String? bookingId,
}) async {
  if (!await requireSignIn(context, reason: SignInReason.chat)) return;
  if (!context.mounted) return;
  try {
    final r = await context.api.post('/chat/threads', {
      'topic': topic,
      'booking_id': bookingId,
    }) as Json;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatRoomScreen(threadId: r['id'] as String, topic: topic),
      ),
    );
  } catch (e) {
    if (context.mounted) showToast(context, context.t.error(e));
  }
}

/// "11월 19일 (목)" with a "변경" pill opening the date picker (design p10, p17).
class VisitDateRow extends StatelessWidget {
  const VisitDateRow({super.key, required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.dfVisitDay,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
              Text(
                dateLabel(date, context.lang),
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _PillButton(
          label: t.dfChange,
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: _firstDay,
              lastDate: _firstDay.add(const Duration(days: _maxDaysAhead - 1)),
              // Hangul falls back to system faces while the bundled one is still loading (no boxes).
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  textTheme: Theme.of(ctx).textTheme.apply(
                    fontFamilyFallback: const [
                      'Apple SD Gothic Neo',
                      'Noto Sans KR',
                      'Malgun Gothic',
                      'sans-serif',
                    ],
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}

/// The design's outlined pill ("변경", "선택"). Capped so a long label at large text wraps
/// instead of squeezing the value beside it down to nothing.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => capped(
    context,
    _pillShare,
    OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
      ),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

/// GET /slots for [date]: start hour -> (available, seats left when nearly full).
Future<Map<int, (bool, int?)>> loadSlots(
  ApiClient api,
  DateTime date, {
  required bool quote,
}) async {
  final r = await api.get(
    '/slots',
    query: {'date': isoDate(date), 'quote': '$quote'},
  ) as List;
  return {
    for (final s in r.cast<Json>())
      (s['start_hour'] as num).toInt(): (
        s['available'] as bool,
        (s['seats_left'] as num?)?.toInt(),
      ),
  };
}

/// Date and arrival hour (design p10): service time, the date row, and the slot sheet.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.draft, this.onDone});
  final BookingDraft draft;
  final void Function(BuildContext context)? onDone;
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  BookingDraft get d => widget.draft;
  Map<int, (bool, int?)> _slots = {};
  bool _loading = false;

  List<int> get _hours => d.service.isQuote ? _quoteSlots : _standardSlots;
  bool _open(int h) => _slots[h]?.$1 ?? true;

  @override
  void initState() {
    super.initState();
    d.date ??= _firstDay;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await loadSlots(context.api, d.date!, quote: d.service.isQuote);
      if (!mounted) return;
      _slots = s;
      if (d.hour != null && !_open(d.hour!)) d.hour = null;
      d.hour ??= _hours.where(_open).firstOrNull;
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickSlot() async {
    final t = context.t;
    var chosen = d.hour;
    final ok = await showAppSheet<bool>(
      context,
      title: t.dfVisitTime,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.gutter,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                dateLabel(d.date!, ctx.lang),
                style: ctx.text.bodySmall,
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: Space.sm),
              tileRows([
                for (final (i, h) in _hours.indexed)
                  StaggerIn(
                    index: i,
                    child: _SlotTile(
                      label: slotRangeLabel(h, ctx.lang),
                      note: !_open(h)
                          ? t.dfSlotClosed
                          : _slots[h]?.$2 != null
                          ? t.seatsLeft('${_slots[h]!.$2}')
                          : null,
                      enabled: _open(h),
                      selected: chosen == h,
                      onTap: () => setSheet(() => chosen = h),
                    ),
                  ),
              ]),
              const SizedBox(height: Space.md),
              PrimaryButton(
                label: t.dfSelectDone,
                onPressed: chosen == null
                    ? null
                    : () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) setState(() => d.hour = chosen);
  }

  /// "어떤 교육을 받나요?" (design p10): the console tip with [trainingTipSlug]. Without one,
  /// what the service covers.
  Future<void> _openTraining() async {
    final ContentItem? tip;
    try {
      tip = (await context.api.get('/content', query: {'kind': 'tip'}) as List)
          .map((e) => ContentItem(e as Json))
          .where((c) => c.j['slug'] == trainingTipSlug)
          .firstOrNull;
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
      return;
    }
    if (!mounted) return;
    final page = tip != null
        ? ContentDetailScreen(item: tip)
        : ServiceScopeScreen(initialGroup: scopeGroupFor(d.service.code));
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _next() {
    if (widget.onDone != null) return widget.onDone!(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => d.service.needsPreparation
            ? PrepToolsScreen(draft: d)
            : CheckoutScreen(draft: d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = context.lang;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(backgroundColor: context.colors.surface),
      body: ListView(
        children: [
          FlowTitle(t.dfDateTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.dfManagerIntro, style: context.text.bodyMedium),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 48),
                          foregroundColor: context.colors.inkSoft,
                          textStyle: context.text.bodyMedium,
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.chevron_right_rounded, size: 18),
                        label: Text(t.dfTrainingLink),
                        onPressed: _openTraining,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                // The manager on a round grey plate (design p10).
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: _managerAvatar / 2,
                    backgroundColor: context.colors.surfaceHigh,
                    child: const Icon3D(
                      'c_staff',
                      size: _managerAvatar * 0.75,
                      idle: Icon3DIdle.float,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const FlowBand(),
          FlowSection(
            children: [
              if (d.minutes > 0) ...[
                Text(
                  t.duration(d.minutes),
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  t.dfServiceTime,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
                const SizedBox(height: Space.lg),
              ],
              VisitDateRow(
                date: d.date!,
                onChanged: (v) {
                  setState(() => d.date = v);
                  _load();
                },
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.dfVisitTime,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.inkMuted,
                          ),
                        ),
                        Text(
                          d.hour == null ? '—' : slotRangeLabel(d.hour!, lang),
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    _PillButton(label: t.dfSelect, onPressed: _pickSlot),
                ],
              ),
              if (_hours.every((h) => !_open(h))) ...[
                const SizedBox(height: Space.sm),
                Text(
                  t.scheduleFull,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: t.next,
          onPressed: d.hour == null ? null : _next,
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.label,
    required this.enabled,
    required this.selected,
    required this.onTap,
    this.note,
  });
  final String label;
  final String? note;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      button: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(Radii.tile),
        child: AnimatedContainer(
          duration: motionFor(context, Motion.micro),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.sm,
          ),
          decoration: BoxDecoration(
            color: !enabled
                ? c.surfaceHigh
                : (selected ? c.primaryTint : c.surface),
            borderRadius: BorderRadius.circular(Radii.tile),
            border: Border.all(
              color: selected ? context.primary : c.line,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.xs,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.text.titleSmall?.copyWith(
                  color: !enabled
                      ? c.inkMuted
                      : (selected ? context.primary : c.ink),
                ),
              ),
              if (note != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(note!, style: context.text.labelSmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
