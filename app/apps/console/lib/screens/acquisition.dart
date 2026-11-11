// Marketing > growth: signups and bookings by first-touch source (UTM / referral), last 30 days.
// Read-only; the server computes the table (GET /admin/acquisition).

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

class AcquisitionTable extends StatefulWidget {
  const AcquisitionTable({super.key});

  @override
  State<AcquisitionTable> createState() => _AcquisitionTableState();
}

class _AcquisitionTableState extends State<AcquisitionTable> {
  List<Json>? _rows;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final res = await context.api.get('/admin/acquisition') as Json;
      if (!mounted) return;
      setState(() => _rows = (res['rows'] as List).cast<Json>());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Widget _cell(BuildContext context, String text, {bool bold = false, bool end = false}) => Expanded(
    child: Text(
      text,
      textAlign: end ? TextAlign.end : TextAlign.start,
      overflow: TextOverflow.ellipsis,
      style: bold ? context.text.labelLarge : context.text.bodyMedium,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('유입 경로별 가입·예약 (최근 30일)', style: context.text.titleMedium),
          Text('Signups and bookings by first-touch source, last 30 days.', style: context.text.bodySmall),
          const SizedBox(height: Space.sm),
          if (_failed) const Text('불러오지 못했어요.')
          else if (rows == null) const Center(child: CircularProgressIndicator())
          else if (rows.isEmpty) const Text('아직 집계된 가입이 없어요.')
          else ...[
            Row(children: [
              _cell(context, '출처 / 매체 / 캠페인', bold: true),
              _cell(context, '가입', bold: true, end: true),
              _cell(context, '예약 고객', bold: true, end: true),
              _cell(context, '예약 수', bold: true, end: true),
            ]),
            const Divider(),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Row(children: [
                  _cell(context, [r['source'], r['medium'], r['campaign']].where((v) => v != '').join(' / ')),
                  _cell(context, '${r['signups']}', end: true),
                  _cell(context, '${r['booked_customers']}', end: true),
                  _cell(context, '${r['bookings']}', end: true),
                ]),
              ),
          ],
          const Divider(height: Space.xxl),
        ],
      ),
    );
  }
}
