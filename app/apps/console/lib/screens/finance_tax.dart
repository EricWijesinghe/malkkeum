import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Downloads one CSV for the given path and query. Owned by the finance screen, which knows how to save.
typedef ExportAt = Future<void> Function(String path, Map<String, String?> query, String fileName);

/// Owner tax tools: quarterly VAT, withholding and tax-invoice exports, the cash-receipt list and the tax-invoice queue.
class TaxSection extends StatelessWidget {
  const TaxSection({super.key, required this.periodQuery, required this.onExport});
  final Map<String, String?> periodQuery;
  final ExportAt onExport;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.tTaxSection, style: context.text.titleLarge),
        const SizedBox(height: Space.md),
        _VatExportCard(onExport: onExport),
        const SizedBox(height: Space.md),
        AppCard(
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => onExport('/admin/finance/export/withholding', periodQuery, 'malkkeum-withholding.csv'),
                icon: const Icon(Icons.download_rounded),
                label: Text(t.tExportWithholding),
              ),
              OutlinedButton.icon(
                onPressed: () => onExport('/admin/finance/export/tax-invoices', periodQuery, 'malkkeum-tax-invoices.csv'),
                icon: const Icon(Icons.download_rounded),
                label: Text(t.tExportTaxInvoices),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(t.tTaxLayoutNote, style: context.text.labelSmall),
        const SizedBox(height: Space.md),
        _TaxInvoiceQueue(periodQuery: periodQuery),
        const SizedBox(height: Space.md),
        _CashReceiptList(periodQuery: periodQuery),
      ],
    );
  }
}

/// Quarterly VAT: a year and one button per quarter. The server answers the quarter, not the period bar.
class _VatExportCard extends StatefulWidget {
  const _VatExportCard({required this.onExport});
  final ExportAt onExport;

  @override
  State<_VatExportCard> createState() => _VatExportCardState();
}

class _VatExportCardState extends State<_VatExportCard> {
  final _year = TextEditingController(text: DateTime.now().year.toString());

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: TextField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.tVatYear, isDense: true),
            ),
          ),
          for (final q in [1, 2, 3, 4])
            FilledButton.tonal(
              onPressed: () => _export(q),
              child: Text(t.tVatQuarter('$q')),
            ),
        ],
      ),
    );
  }

  void _export(int quarter) {
    final year = int.tryParse(_year.text.trim());
    if (year == null || year < 2000 || year > 2100) return;
    widget.onExport('/admin/finance/export/vat', {'year': '$year', 'quarter': '$quarter'}, 'malkkeum-vat-$year-Q$quarter.csv');
  }
}

/// Tax-invoice queue: requests waiting for 홈택스. Marking one issued records its approval number.
class _TaxInvoiceQueue extends StatelessWidget {
  const _TaxInvoiceQueue({required this.periodQuery});
  final Map<String, String?> periodQuery;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<List<Json>>(
      key: ValueKey(periodQuery.toString()),
      load: () async => (await context.api.get('/admin/finance/tax-invoices', query: periodQuery) as List).cast<Json>(),
      builder: (context, rows, reload) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.tTaxInvoices, style: context.text.titleMedium),
            if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(t.tQueueEmpty)),
            for (final r in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${r['company_name']} · ${r['business_number']}'),
                subtitle: Text(_invoiceLine(t, r)),
                trailing: r['state'] == 'requested'
                    ? FilledButton(onPressed: () => _markIssued(context, r, reload), child: Text(t.tMarkIssued))
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  String _invoiceLine(T t, Json r) {
    final approval = r['approval_number'];
    return approval == null ? t.tCashPending : '${t.tApprovalNumber}: $approval · ${r['issued_on']}';
  }

  Future<void> _markIssued(BuildContext context, Json r, Future<void> Function() reload) async {
    final input = await showDialog<_IssuedInput>(context: context, builder: (_) => const _ApprovalDialog());
    if (input == null || !context.mounted) return;
    await context.api.post('/admin/finance/tax-invoices/${r['id']}/issued', {
      'approval_number': input.approval,
      'issued_on': input.issuedOn,
    });
    await reload();
  }
}

class _IssuedInput {
  const _IssuedInput(this.approval, this.issuedOn);
  final String approval;
  final String issuedOn;
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog();

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _approval = TextEditingController();
  DateTime _day = DateTime.now();

  @override
  void dispose() {
    _approval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.tMarkIssued),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _approval, decoration: InputDecoration(labelText: t.tApprovalNumber)),
          const SizedBox(height: Space.sm),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDate: _day);
              if (picked != null) setState(() => _day = picked);
            },
            child: Text('${t.tIssuedOn}: ${_ymd(_day)}'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
        FilledButton(
          onPressed: () {
            final approval = _approval.text.trim();
            if (approval.isEmpty) return;
            Navigator.of(context).pop(_IssuedInput(approval, _ymd(_day)));
          },
          child: Text(t.tMarkIssued),
        ),
      ],
    );
  }
}

/// Cash receipts issued or pending in the period. Only failed issues can be reissued.
class _CashReceiptList extends StatelessWidget {
  const _CashReceiptList({required this.periodQuery});
  final Map<String, String?> periodQuery;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<List<Json>>(
      key: ValueKey(periodQuery.toString()),
      load: () async => (await context.api.get('/admin/finance/cash-receipts', query: periodQuery) as List).cast<Json>(),
      builder: (context, rows, reload) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.tCashReceipts, style: context.text.titleMedium),
            if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(t.tQueueEmpty)),
            for (final r in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${r['purpose']} · ****${r['identity_last4']} · ${_stateLabel(t, r['state'] as String)}'),
                subtitle: Text(_receiptLine(r)),
                trailing: r['state'] == 'failed'
                    ? TextButton(onPressed: () => _reissue(context, r, reload), child: Text(t.tReissue))
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  String _stateLabel(T t, String state) => switch (state) {
    'issued' => t.tCashIssued,
    'failed' => t.tCashFailed,
    'cancelled' => t.tCashCancelled,
    _ => t.tCashPending,
  };

  String _receiptLine(Json r) {
    final failure = r['failure_reason'];
    return failure != null ? '$failure' : '${r['issue_number'] ?? ''}';
  }

  Future<void> _reissue(BuildContext context, Json r, Future<void> Function() reload) async {
    await context.api.post('/admin/finance/cash-receipts/${r['id']}/reissue', {});
    await reload();
  }
}

/// Owner sets a partner's withholding class from a payout row. It applies to payouts created after the change.
Future<void> setPartnerTaxType(BuildContext context, Json payout, Future<void> Function() reload) async {
  final t = context.t;
  final messenger = ScaffoldMessenger.of(context);
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(t.tTaxType),
      children: [
        SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop('freelancer'), child: Text(t.tTaxFreelancer)),
        SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop('business'), child: Text(t.tTaxBusiness)),
      ],
    ),
  );
  if (picked == null || picked == payout['tax_type'] || !context.mounted) return;
  try {
    await context.api.post('/admin/settlements/partners/${payout['pro_id']}/tax-type', {'tax_type': picked});
    await reload();
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(t.error(e))));
  }
}

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
