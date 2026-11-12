import 'api.dart';
import 'models.dart';

/// Payment channels the server supports. `flow` decides the path:
/// billing = saved one-tap method (register once, then POST /bookings with payment_method_id);
/// checkout = PG window per payment (POST /checkouts, launch, confirm).
class PayChannel {
  const PayChannel({required this.code, required this.flow});
  final String code;
  final String flow;

  bool get isBilling => flow == 'billing';

  factory PayChannel.fromJson(Json j) => PayChannel(
    code: j['code'] as String,
    flow: j['flow'] as String? ?? 'checkout',
  );
}

Future<List<PayChannel>> fetchPayChannels(ApiClient api) async {
  final list = await api.get('/payments/methods') as List;
  return list.map((e) => PayChannel.fromJson(e as Json)).toList();
}

/// Response of POST /v1/checkouts: everything the PG window needs.
class CheckoutIntent {
  const CheckoutIntent({
    required this.id,
    required this.amount,
    required this.orderName,
    required this.method,
    required this.storeId,
    required this.channelKey,
    this.cashReceipts = false,
  });

  final String id;
  final int amount;
  final String orderName;
  final String method;
  final String storeId;
  final String channelKey;

  /// Server has 현금영수증 switched on; receipt options are shown only then.
  final bool cashReceipts;

  factory CheckoutIntent.fromJson(Json j) => CheckoutIntent(
    id: j['id'] as String,
    amount: (j['amount'] as num).toInt(),
    orderName: j['order_name'] as String? ?? '',
    method: j['method'] as String,
    storeId: j['store_id'] as String? ?? '',
    channelKey: j['channel_key'] as String? ?? '',
    cashReceipts: j['cash_receipts'] == true,
  );
}

/// Bank details for a virtual-account deposit.
class VirtualAccount {
  const VirtualAccount({
    required this.bank,
    required this.accountNumber,
    required this.holder,
    required this.due,
  });

  final String bank;
  final String accountNumber;
  final String holder;
  final DateTime? due;

  factory VirtualAccount.fromJson(Json j) => VirtualAccount(
    bank: j['bank'] as String? ?? '',
    accountNumber: j['account_number'] as String? ?? '',
    holder: j['holder'] as String? ?? '',
    due: DateTime.tryParse(j['due'] as String? ?? '')?.toLocal(),
  );
}

/// A virtual account still waiting for money (GET /v1/checkouts?status=awaiting_deposit).
class PendingDeposit {
  const PendingDeposit({
    required this.id,
    required this.amount,
    required this.account,
    this.bookingId,
    this.orderName = '',
  });

  final String id;
  final int amount;
  final VirtualAccount account;
  final String? bookingId;
  final String orderName;

  /// Items without a virtual_account are skipped rather than failing the whole list.
  static PendingDeposit? tryParse(Json j) {
    final va = j['virtual_account'] as Json?;
    if (va == null || j['id'] == null) return null;
    return PendingDeposit(
      id: j['id'] as String,
      amount: (j['amount'] as num? ?? 0).toInt(),
      account: VirtualAccount.fromJson(va),
      bookingId: j['booking_id'] as String?,
      orderName: j['order_name'] as String? ?? '',
    );
  }
}

Future<List<PendingDeposit>> fetchPendingDeposits(ApiClient api) async {
  final list =
      await api.get('/checkouts', query: {'status': 'awaiting_deposit'})
          as List;
  return [for (final e in list) ?PendingDeposit.tryParse(e as Json)];
}
