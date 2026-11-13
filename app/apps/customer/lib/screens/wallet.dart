// Points wallet, payment history with receipts, and refund status. Every number comes from the
// server; the receipt's business details come from the public business profile (GET /brand).

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

String _ymd(Object? iso) {
  final d = iso is String ? DateTime.tryParse(iso)?.toLocal() : null;
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}.${two(d.month)}.${two(d.day)}';
}

String _kindLabel(BuildContext context, String kind) {
  final t = context.t;
  return switch (kind) {
    'earn' => t.walletKindEarn,
    'welcome' => t.walletKindWelcome,
    'referral' => t.walletKindReferral,
    'refund' => t.walletKindRefund,
    'spend' => t.walletKindSpend,
    'expire' => t.walletKindExpire,
    _ => t.walletKindOther,
  };
}

/// Points balance, the "expiring soon" line, and the ledger history.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Json> _points = _load();

  Future<Json> _load() async => (await context.api.get('/me/points')) as Json;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.walletTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          final f = _load();
          setState(() => _points = f);
          await f;
        },
        child: FutureBuilder<Json>(
          future: _points,
          builder: (context, snap) {
            if (snap.hasError) return ListView(children: [Text(t.error(snap.error!))]);
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return _body(context, snap.data!);
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Json p) {
    final t = context.t;
    final balance = (p['balance'] as num? ?? 0).toInt();
    final expiring = (p['expiring_soon'] as num? ?? 0).toInt();
    final days = (p['notify_days'] as num? ?? 30).toInt();
    final entries = ((p['entries'] as List?) ?? const []).cast<Json>();
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.walletBalance, style: context.text.bodyMedium?.copyWith(color: context.colors.inkSoft)),
              const SizedBox(height: Space.xs),
              Text(t.walletPoints('$balance'), style: context.text.headlineMedium),
              if (p['enabled'] != true) ...[
                const SizedBox(height: Space.sm),
                Text(t.walletOff, style: context.text.bodySmall),
              ] else if (expiring > 0) ...[
                const SizedBox(height: Space.sm),
                Text(t.walletExpiring('$days', '$expiring'), style: context.text.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(t.walletHistory, style: context.text.titleSmall),
        const SizedBox(height: Space.sm),
        if (entries.isEmpty)
          Text(t.walletEmpty, style: context.text.bodyMedium)
        else
          for (final e in entries) _entryRow(context, e),
      ],
    );
  }

  Widget _entryRow(BuildContext context, Json e) {
    final amount = (e['amount'] as num).toInt();
    final sign = amount > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_kindLabel(context, e['kind'] as String), style: context.text.bodyMedium),
                Text(_ymd(e['at']), style: context.text.labelSmall),
              ],
            ),
          ),
          Text('$sign$amount P', style: context.text.titleSmall?.copyWith(color: amount > 0 ? context.primary : context.colors.inkSoft)),
        ],
      ),
    );
  }
}

/// Every payment the customer made, with its status (refunds included) and a receipt sheet.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<Json>> _rows = _load();

  Future<List<Json>> _load() async => ((await context.api.get('/checkouts')) as List).cast<Json>();

  String _status(BuildContext context, String s) {
    final t = context.t;
    return switch (s) {
      'paid' => t.payStatusPaid,
      'refunded' => t.payStatusRefunded,
      'refund_pending' => t.payStatusRefundPending,
      'pending' || 'awaiting_deposit' => t.payStatusPending,
      _ => t.payStatusClosed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.payHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          final f = _load();
          setState(() => _rows = f);
          await f;
        },
        child: FutureBuilder<List<Json>>(
          future: _rows,
          builder: (context, snap) {
            if (snap.hasError) return ListView(children: [Text(t.error(snap.error!))]);
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final rows = snap.data!;
            if (rows.isEmpty) {
              return ListView(children: [EmptyState(icon: Icons.receipt_long_rounded, title: t.payHistoryEmpty)]);
            }
            return ListView(
              padding: const EdgeInsets.all(Space.gutter),
              children: [
                for (final r in rows)
                  ListTile(
                    key: ValueKey('pay-row-${r['id']}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.won((r['amount'] as num).toInt()), style: context.text.titleSmall),
                    subtitle: Text('${t.payMethod(r['method'] as String)} · ${_ymd(r['created_at'])} · ${_status(context, r['status'] as String)}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showAppSheet<void>(
                      context,
                      title: t.receiptTitle,
                      builder: (_) => ReceiptView(checkout: r),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Receipt for one checkout: amount, method, date, status, and the business details from /brand.
class ReceiptView extends StatefulWidget {
  const ReceiptView({super.key, required this.checkout});
  final Json checkout;

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  late final Future<Json> _brand = _loadBrand();

  Future<Json> _loadBrand() async => (await context.api.get('/brand')) as Json;

  String _text(BuildContext context, Json brand) {
    final t = context.t;
    final c = widget.checkout;
    final lines = [
      t.receiptTitle,
      '${t.receiptDate}: ${_ymd(c['created_at'])}',
      '${t.receiptLegal}: ${brand['legal_name'] ?? brand['name'] ?? ''}',
      '${t.receiptRegNo}: ${brand['registration_no'] ?? ''}',
      '${t.receiptAddr}: ${brand['address'] ?? ''}',
      '${t.receiptPhone}: ${brand['support_phone'] ?? ''}',
      '${t.payMethod(c['method'] as String)}: ${context.won((c['amount'] as num).toInt())}',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = widget.checkout;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
      child: FutureBuilder<Json>(
        future: _brand,
        builder: (context, snap) {
          final brand = snap.data ?? const <String, dynamic>{};
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _line(context, t.receiptDate, _ymd(c['created_at'])),
                    _line(context, t.apPgReceiptMethod, t.payMethod(c['method'] as String)),
                    _line(context, t.apPgReceiptAmount, context.won((c['amount'] as num).toInt())),
                    _line(context, t.apPgReceiptApproval, (c['id'] as String).substring(0, 8)),
                    _line(context, t.receiptLegal, '${brand['legal_name'] ?? brand['name'] ?? ''}'),
                    _line(context, t.receiptRegNo, '${brand['registration_no'] ?? ''}'),
                    _line(context, t.receiptAddr, '${brand['address'] ?? ''}'),
                    _line(context, t.receiptPhone, '${brand['support_phone'] ?? ''}'),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(t.receiptNote, style: context.text.labelSmall, textAlign: TextAlign.center),
              const SizedBox(height: Space.md),
              PrimaryButton(
                key: const ValueKey('receipt-copy'),
                label: t.receiptCopy,
                onPressed: snap.hasData
                    ? () async {
                        await Clipboard.setData(ClipboardData(text: _text(context, brand)));
                        if (context.mounted) showToast(context, t.receiptCopied);
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        children: [
          Text(k, style: context.text.bodySmall?.copyWith(color: context.colors.inkSoft)),
          const Spacer(),
          Flexible(child: Text(v, style: context.text.bodySmall, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
