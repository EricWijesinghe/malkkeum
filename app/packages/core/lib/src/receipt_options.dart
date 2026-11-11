import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'checkout.dart';
import 'i18n.dart';
import 'models.dart';

/// Payment methods that can carry a 현금영수증 (bank transfer and virtual account). Mirrors the server rule.
const cashReceiptMethods = {'transfer', 'virtual_account'};

/// A 현금영수증 request: personal (phone number) or business (business registration number).
class CashReceiptRequest {
  const CashReceiptRequest({required this.corporate, required this.identity});
  final bool corporate;
  final String identity;
}

/// A 세금계산서 request with the buyer's business details.
class InvoiceRequest {
  const InvoiceRequest({required this.businessNumber, required this.companyName, required this.representative, required this.email});
  final String businessNumber;
  final String companyName;
  final String representative;
  final String email;
}

/// What the customer asked for before paying. Empty when nothing was requested.
class ReceiptChoice {
  const ReceiptChoice({this.cash, this.invoice});
  final CashReceiptRequest? cash;
  final InvoiceRequest? invoice;

  bool get isEmpty => cash == null && invoice == null;
}

/// The cash-receipt option the customer picked last time.
enum CashChoice { none, phone, business }

/// The remembered choice. The identity is personal data, so it lives in secure storage on this device only.
class RememberedReceipt {
  const RememberedReceipt({this.seen = false, this.kind = CashChoice.none, this.identity = ''});
  final bool seen;
  final CashChoice kind;
  final String identity;

  factory RememberedReceipt.fromChoice(ReceiptChoice choice) {
    final cash = choice.cash;
    if (cash == null) return const RememberedReceipt(seen: true);
    return RememberedReceipt(
      seen: true,
      kind: cash.corporate ? CashChoice.business : CashChoice.phone,
      identity: cash.identity,
    );
  }

  /// The request this choice implies for a checkout. Empty when the method cannot carry a receipt or nothing is remembered.
  ReceiptChoice toChoice({required bool cashAllowed}) {
    if (kind == CashChoice.none || identity.isEmpty || !cashAllowed) return const ReceiptChoice();
    return ReceiptChoice(cash: CashReceiptRequest(corporate: kind == CashChoice.business, identity: identity));
  }
}

/// Reads and writes the remembered choice. Storage failures count as "never asked", so checkout still works.
class ReceiptMemory {
  ReceiptMemory({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _seen = 'receipt.seen';
  static const _kind = 'receipt.kind';
  static const _identity = 'receipt.identity';

  Future<RememberedReceipt> load() async {
    try {
      if (await _storage.read(key: _seen) != '1') return const RememberedReceipt();
      final kind = await _storage.read(key: _kind);
      return RememberedReceipt(
        seen: true,
        kind: CashChoice.values.firstWhere((k) => k.name == kind, orElse: () => CashChoice.none),
        identity: await _storage.read(key: _identity) ?? '',
      );
    } on Exception {
      return const RememberedReceipt();
    }
  }

  Future<void> save(RememberedReceipt r) async {
    try {
      await _storage.write(key: _seen, value: r.seen ? '1' : '0');
      await _storage.write(key: _kind, value: r.kind.name);
      await _storage.write(key: _identity, value: r.identity);
    } on Exception {
      // Not remembered this time; the customer is asked again next checkout.
    }
  }
}

/// Asks for receipts before the PG window opens. Pre-selects [initial]. Null when the customer closes the sheet.
Future<ReceiptChoice?> showReceiptOptions(BuildContext context, {required bool cashAllowed, RememberedReceipt initial = const RememberedReceipt()}) =>
    showAppSheet<ReceiptChoice>(
      context,
      title: context.t.tReceiptOptions,
      builder: (_) => _ReceiptForm(cashAllowed: cashAllowed, initial: initial),
    );

/// Saves a choice against a checkout that is not paid yet. Returns an error code, or null on success.
Future<String?> saveReceiptChoice(ApiClient api, String checkoutId, ReceiptChoice choice) async {
  try {
    final cash = choice.cash;
    if (cash != null) {
      await api.put('/checkouts/$checkoutId/cash-receipt', {
        'purpose': cash.corporate ? 'CORPORATE' : 'PERSONAL',
        'identity': cash.identity,
      });
    }
    final invoice = choice.invoice;
    if (invoice != null) {
      await api.put('/checkouts/$checkoutId/tax-invoice', {
        'business_number': invoice.businessNumber,
        'company_name': invoice.companyName,
        'representative': invoice.representative,
        'email': invoice.email,
      });
    }
    return null;
  } on ApiException catch (e) {
    return e.code;
  }
}

/// The step CheckoutService runs before paying. Hidden entirely while the server flag is off.
/// First checkout: asks, then remembers. Later checkouts: applies the remembered cash choice silently.
Future<String?> Function(CheckoutIntent intent) receiptStep(BuildContext context, ApiClient api, ReceiptMemory memory) => (intent) async {
      if (!intent.cashReceipts) return null;
      final cashAllowed = cashReceiptMethods.contains(intent.method);
      final remembered = await memory.load();
      final ReceiptChoice choice;
      if (remembered.seen) {
        choice = remembered.toChoice(cashAllowed: cashAllowed);
      } else {
        final asked = await showReceiptOptions(context, cashAllowed: cashAllowed);
        if (asked == null) return null;
        await memory.save(RememberedReceipt.fromChoice(asked));
        choice = asked;
      }
      if (choice.isEmpty) return null;
      return saveReceiptChoice(api, intent.id, choice);
    };

/// Small "영수증 설정" line for the payment picker. Shown only when the server flag is on.
/// Tapping it edits the remembered choice without paying.
class ReceiptSettingsLine extends StatelessWidget {
  const ReceiptSettingsLine({super.key, required this.api, required this.memory});
  final ApiClient api;
  final ReceiptMemory memory;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _enabled(),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: Text(context.t.tReceiptSettings),
          ),
        );
      },
    );
  }

  Future<bool> _enabled() async {
    try {
      final r = await api.get('/receipt-options') as Json;
      return r['cash_receipts'] == true;
    } on ApiException {
      return false;
    }
  }

  Future<void> _edit(BuildContext context) async {
    final remembered = await memory.load();
    if (!context.mounted) return;
    final choice = await showReceiptOptions(context, cashAllowed: true, initial: remembered);
    if (choice == null) return;
    await memory.save(RememberedReceipt.fromChoice(choice));
  }
}

class _ReceiptForm extends StatefulWidget {
  const _ReceiptForm({required this.cashAllowed, required this.initial});
  final bool cashAllowed;
  final RememberedReceipt initial;

  @override
  State<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<_ReceiptForm> {
  late bool _cash = widget.initial.kind != CashChoice.none;
  late bool _corporate = widget.initial.kind == CashChoice.business;
  bool _invoice = false;
  late final _phone = TextEditingController(text: widget.initial.kind == CashChoice.phone ? widget.initial.identity : '');
  late final _business = TextEditingController(text: widget.initial.kind == CashChoice.business ? widget.initial.identity : '');
  final _company = TextEditingController();
  final _representative = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    for (final c in [_phone, _business, _company, _representative, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final cash = _cash && (_corporate ? _business.text.trim().isNotEmpty : _phone.text.trim().isNotEmpty)
        ? CashReceiptRequest(corporate: _corporate, identity: _corporate ? _business.text.trim() : _phone.text.trim())
        : null;
    final invoice = _invoice && _business.text.trim().isNotEmpty && _company.text.trim().isNotEmpty && _email.text.trim().isNotEmpty
        ? InvoiceRequest(
            businessNumber: _business.text.trim(),
            companyName: _company.text.trim(),
            representative: _representative.text.trim(),
            email: _email.text.trim(),
          )
        : null;
    Navigator.of(context).pop(ReceiptChoice(cash: cash, invoice: invoice));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.cashAllowed) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.tWantCashReceipt),
              value: _cash,
              onChanged: (v) => setState(() => _cash = v),
            ),
            if (_cash) ...[
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(t.tCashForIncome)),
                  ButtonSegment(value: true, label: Text(t.tCashForBusiness)),
                ],
                selected: {_corporate},
                onSelectionChanged: (s) => setState(() => _corporate = s.first),
              ),
              const SizedBox(height: Space.sm),
              if (!_corporate)
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t.tPhoneForReceipt))
              else if (!_invoice)
                TextField(controller: _business, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.tBusinessNumber)),
            ],
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.tWantTaxInvoice),
            value: _invoice,
            onChanged: (v) => setState(() => _invoice = v),
          ),
          if (_invoice) ...[
            TextField(controller: _business, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.tBusinessNumber)),
            TextField(controller: _company, decoration: InputDecoration(labelText: t.tCompanyName)),
            TextField(controller: _representative, decoration: InputDecoration(labelText: t.tRepresentative)),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: t.tInvoiceEmail)),
          ],
          const SizedBox(height: Space.md),
          FilledButton(onPressed: _save, child: Text(t.tReceiptSave)),
        ],
      ),
    );
  }
}
