import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'checkout.dart';
import 'i18n.dart';

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

/// Asks for receipts before the PG window opens. Null when the customer closes the sheet.
Future<ReceiptChoice?> showReceiptOptions(BuildContext context, {required bool cashAllowed}) => showAppSheet<ReceiptChoice>(
      context,
      title: context.t.tReceiptOptions,
      builder: (_) => _ReceiptForm(cashAllowed: cashAllowed),
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

/// The step CheckoutService runs before paying. Does nothing unless the server has receipts switched on,
/// so the option is hidden for every customer while the flag is off.
Future<String?> Function(CheckoutIntent intent) receiptStep(BuildContext context, ApiClient api) => (intent) async {
      if (!intent.cashReceipts) return null;
      final choice = await showReceiptOptions(context, cashAllowed: cashReceiptMethods.contains(intent.method));
      if (choice == null || choice.isEmpty) return null;
      return saveReceiptChoice(api, intent.id, choice);
    };

class _ReceiptForm extends StatefulWidget {
  const _ReceiptForm({required this.cashAllowed});
  final bool cashAllowed;

  @override
  State<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<_ReceiptForm> {
  bool _cash = false;
  bool _corporate = false;
  bool _invoice = false;
  final _phone = TextEditingController();
  final _business = TextEditingController();
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
              if (_corporate && !_invoice)
                TextField(controller: _business, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.tBusinessNumber))
              else if (_corporate)
                Text(t.tBusinessNumber, style: Theme.of(context).textTheme.bodySmall)
              else
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t.tPhoneForReceipt)),
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
