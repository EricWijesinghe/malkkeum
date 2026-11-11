import 'api.dart';
import 'gen/app_localizations.dart';
import 'i18n.dart';

/// Server codes this layer gives their own copy. Anything else falls back to the generic labels.
enum PayFailure {
  providerNotConfigured,
  phoneTaken,
  paidSlotFull,
  checkoutExpired,
  slotFull,
  paymentFailed,
  network,
  unknown,
}

/// `paid_slot_full` is set by CheckoutService when confirm fails with slot_full: the server
/// has already cancelled the payment, so the copy must say so.
PayFailure payFailureFor(String code) => switch (code) {
  'provider_not_configured' => PayFailure.providerNotConfigured,
  'phone_taken' => PayFailure.phoneTaken,
  'paid_slot_full' => PayFailure.paidSlotFull,
  'checkout_expired' => PayFailure.checkoutExpired,
  'slot_full' => PayFailure.slotFull,
  'payment_failed' => PayFailure.paymentFailed,
  'network' || 'timeout' => PayFailure.network,
  _ => PayFailure.unknown,
};

/// Friendly, localized copy for sign-in, identity and checkout errors.
extension PayLabels on T {
  /// For any thrown error on a sign-in, identity or payment call.
  String payError(Object e) {
    if (e is ApiException) return checkoutFailure(e.code);
    return errorGeneric;
  }

  /// For a failure code, from either an ApiException or a CheckoutFailed result.
  String checkoutFailure(String code) => switch (payFailureFor(code)) {
    PayFailure.providerNotConfigured => apProviderNotConfigured,
    PayFailure.phoneTaken => apPhoneTaken,
    PayFailure.paidSlotFull => apErrSlotFullRefunded,
    PayFailure.checkoutExpired => apErrCheckoutExpired,
    PayFailure.slotFull => err_slot_full,
    PayFailure.paymentFailed => err_payment_failed,
    PayFailure.network => errorNetwork,
    PayFailure.unknown => error(ApiException(400, code)),
  };

  /// Label for a server channel code.
  String payMethod(String code) => switch (code) {
    'card' => apMethodCard,
    'kakaopay' => apMethodKakao,
    'naverpay' => apMethodNaver,
    'tosspay' => apMethodToss,
    'payco' => apMethodPayco,
    'samsungpay' => apMethodSamsung,
    'applepay' => apMethodApple,
    'transfer' => apMethodTransfer,
    'virtual_account' => apMethodVirtual,
    'phone' => apMethodPhone,
    _ => apMethodUnknown,
  };
}
