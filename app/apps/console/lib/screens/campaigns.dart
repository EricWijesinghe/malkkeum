import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Audience size with marketing consent, for the given segment list.
typedef PreviewFn = Future<Json> Function(List<Json> audience);

/// Creates the campaign and schedules it: `at` null means send on the next pass.
typedef SubmitFn = Future<void> Function(Json body, DateTime? at);

/// Test send to the operator's own phone (SMS format, not logged as a campaign).
typedef TestFn = Future<void> Function(String phone, String body, String optout);

enum AudienceKind { all, neverBooked, lapsed }

/// Segment JSON as the server expects it (`Segment` in marketing.rs).
List<Json> audienceJson(AudienceKind kind, int days) => switch (kind) {
  AudienceKind.all => const [],
  AudienceKind.neverBooked => [
    {'type': 'never_booked'},
  ],
  AudienceKind.lapsed => [
    {'type': 'last_booking_older_than', 'days': days},
  ],
};

/// The SMS text customers get, formatted like the server's `sms_ad_text`.
String smsAdText(String body, String optout) => '(광고) $body\n무료수신거부 $optout';

/// Opt-out numbers: digits with optional hyphens, 9 to 12 digits.
bool validOptout(String v) => RegExp(r'^\d{9,12}$').hasMatch(v.replaceAll('-', ''));

/// Campaign builder: audience with live consent count, channel, copy with the ad preview, schedule,
/// and a test send. Network calls come in as callbacks so the screen can be tested without a server.
class CampaignBuilder extends StatefulWidget {
  const CampaignBuilder({super.key, required this.preview, required this.submit, required this.testSend});
  final PreviewFn preview;
  final SubmitFn submit;
  final TestFn testSend;

  @override
  State<CampaignBuilder> createState() => _CampaignBuilderState();
}

class _CampaignBuilderState extends State<CampaignBuilder> {
  AudienceKind _kind = AudienceKind.all;
  final _days = TextEditingController(text: '30');
  String _channel = 'push';
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _optout = TextEditingController();
  final _phone = TextEditingController();
  int? _total;
  int? _consented;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  @override
  void dispose() {
    for (final c in [_days, _title, _body, _optout, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _daysValue => int.tryParse(_days.text.trim()) ?? 0;

  Future<void> _refreshCount() async {
    try {
      final r = await widget.preview(audienceJson(_kind, _daysValue));
      if (!mounted) return;
      setState(() {
        _total = (r['total'] as num).toInt();
        _consented = (r['consented'] as num).toInt();
      });
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  /// Title and body are required; SMS also needs a valid 080 opt-out number.
  bool get _canSend =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty && (_channel == 'push' || validOptout(_optout.text.trim()));

  Future<void> _pickTime(T t) async {
    final now = DateTime.now();
    final day = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 90)));
    if (day == null || !mounted) return;
    final hm = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (hm == null || !mounted) return;
    await _send(t, DateTime(day.year, day.month, day.day, hm.hour, hm.minute).toUtc());
  }

  Future<void> _send(T t, DateTime? at) async {
    if (!_canSend) return;
    setState(() => _busy = true);
    try {
      await widget.submit({
        'name': _title.text.trim(),
        'channel': _channel,
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'audience': audienceJson(_kind, _daysValue),
        if (_channel == 'sms') 'optout_number': _optout.text.trim(),
      }, at);
      if (mounted) showToast(context, t.cmSaved);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.cmAudience, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: [
            for (final (kind, label) in [
              (AudienceKind.all, t.cmSegAll),
              (AudienceKind.neverBooked, t.cmSegNever),
              (AudienceKind.lapsed, t.cmSegLapsed(_daysValue.toString())),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _kind == kind,
                onSelected: (_) {
                  setState(() => _kind = kind);
                  _refreshCount();
                },
              ),
          ],
        ),
        if (_kind == AudienceKind.lapsed)
          TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: t.cmDays),
            onSubmitted: (_) => _refreshCount(),
          ),
        if (_total != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(t.cmConsentCount('${_total ?? 0}', '${_consented ?? 0}')),
          ),
        const SizedBox(height: 12),
        Text(t.cmChannel, style: Theme.of(context).textTheme.titleMedium),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'push', label: Text(t.cmPush)),
            ButtonSegment(value: 'sms', label: Text(t.cmSms)),
          ],
          selected: {_channel},
          onSelectionChanged: (s) => setState(() => _channel = s.first),
        ),
        TextField(controller: _title, decoration: InputDecoration(labelText: t.cmTitle), onChanged: (_) => setState(() {})),
        TextField(controller: _body, minLines: 2, maxLines: 5, decoration: InputDecoration(labelText: t.cmBody), onChanged: (_) => setState(() {})),
        if (_channel == 'sms')
          TextField(
            controller: _optout,
            decoration: InputDecoration(
              labelText: t.cmOptout,
              errorText: _optout.text.trim().isNotEmpty && !validOptout(_optout.text.trim()) ? t.cmNeedOptout : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        const SizedBox(height: 12),
        Text(t.cmPreview, style: Theme.of(context).textTheme.titleMedium),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_channel == 'sms' ? smsAdText(_body.text, _optout.text) : '${_title.text}\n${_body.text}'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t.cmTestSend)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : () => widget.testSend(_phone.text.trim(), _body.text.trim(), _optout.text.trim()),
              child: Text(t.cmTestSend),
            ),
            OutlinedButton(onPressed: _busy || !_canSend ? null : () => _pickTime(t), child: Text(t.cmSchedule)),
            FilledButton(onPressed: _busy || !_canSend ? null : () => _send(t, null), child: Text(t.cmSendNow)),
          ],
        ),
      ],
    );
  }
}
