import 'package:core/core.dart';
import 'package:test_support/test_support.dart';

/// Registers the endpoints [AppState.loadAll] and the Shell tabs call on start-up.
/// The first matching route wins, so register a test-specific override before calling this.
void stockCustomerApi(
  FakeApi api, {
  String name = '지민',
  List<Json>? addresses,
  List<Json>? coupons,
  List<Json>? methods,
  List<Json>? bookings,
  List<Json>? threads,
}) {
  api
    ..reply('GET', '/me', {'name': name, 'phone': '01012345678', 'email': null})
    ..reply('PATCH', '/me', {'name': name, 'phone': '01012345678', 'email': null})
    ..reply('GET', '/services', catalogJson())
    ..reply('GET', '/me/addresses', addresses ?? [addressJson()])
    ..reply('GET', '/me/coupons', coupons ?? const <Json>[])
    ..reply('GET', '/me/payment-methods', methods ?? [paymentMethodJson()])
    ..reply('GET', '/chat/threads', threads ?? const <Json>[])
    ..reply('GET', '/bookings', bookings ?? const <Json>[])
    ..reply('GET', '/content', [contentJson(kind: 'notice', title: const {'ko': '점검 안내', 'en': 'Maintenance'})])
    ..reply('GET', '/me/notifications', const <Json>[]);
}
