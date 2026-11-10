import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Customer data the whole app reads: profile, catalogue, addresses, coupons, methods, unread.
class AppState extends ChangeNotifier {
  AppState(this.api, this.realtime) {
    realtime.events.listen(_onEvent);
  }

  final ApiClient api;
  final Realtime realtime;

  String name = '';
  String phone = '';
  String? email;
  List<Service> services = const [];
  List<Address> addresses = const [];
  List<Coupon> coupons = const [];
  List<PaymentMethod> methods = const [];
  int unreadChats = 0;

  /// Bumped on any booking change so lists can refetch.
  int bookingsVersion = 0;

  Service? service(String code) =>
      services.where((s) => s.code == code).firstOrNull;

  Future<void> loadAll() async {
    await Future.wait([
      loadProfile(),
      loadServices(),
      loadAddresses(),
      loadCoupons(),
      loadMethods(),
      loadUnread(),
    ]);
  }

  Future<void> loadProfile() async {
    final p = await api.get('/me') as Json;
    name = p['name'] as String? ?? '';
    phone = p['phone'] as String? ?? '';
    email = p['email'] as String?;
    notifyListeners();
  }

  Future<void> loadServices() async {
    services = (await api.get('/services') as List)
        .map((e) => Service.fromJson(e as Json))
        .toList();
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    addresses = (await api.get('/me/addresses') as List)
        .map((e) => Address.fromJson(e as Json))
        .toList();
    notifyListeners();
  }

  Future<void> loadCoupons() async {
    coupons = (await api.get('/me/coupons') as List)
        .map((e) => Coupon.fromJson(e as Json))
        .toList();
    notifyListeners();
  }

  Future<void> loadMethods() async {
    methods = (await api.get('/me/payment-methods') as List)
        .map((e) => PaymentMethod.fromJson(e as Json))
        .toList();
    notifyListeners();
  }

  Future<void> loadUnread() async {
    final threads = (await api.get('/chat/threads') as List).map(
      (e) => ChatThread.fromJson(e as Json),
    );
    unreadChats = threads.fold(0, (sum, t) => sum + t.unreadMember);
    notifyListeners();
  }

  Future<Address> saveAddress(Json input, {String? id}) async {
    final r = id == null
        ? await api.post('/me/addresses', input)
        : await api.put('/me/addresses/$id', input);
    await loadAddresses();
    return Address.fromJson(r as Json);
  }

  Future<void> deleteAddress(String id) async {
    await api.delete('/me/addresses/$id');
    await loadAddresses();
  }

  Future<PaymentMethod> addMethod(String provider, String displayName) async {
    // shortcut: auth_key comes from the gateway's card-registration SDK once the PG contract exists.
    final r = await api.post('/me/payment-methods', {
      'provider': provider,
      'auth_key': 'dev-${DateTime.now().millisecondsSinceEpoch}',
      'display_name': displayName,
    });
    await loadMethods();
    return PaymentMethod.fromJson(r as Json);
  }

  Future<void> deleteMethod(String id) async {
    await api.delete('/me/payment-methods/$id');
    await loadMethods();
  }

  void bookingsChanged() {
    bookingsVersion++;
    notifyListeners();
  }

  void _onEvent(Json e) {
    switch (e['type']) {
      case 'chat.message' || 'resync':
        loadUnread().ignore();
      case 'booking.status' ||
          'booking.cancelled' ||
          'booking.completed' ||
          'booking.reschedule_confirmed':
        bookingsChanged();
    }
    if (e['type'] == 'resync') bookingsChanged();
  }
}

/// Gives every screen the app services without a DI package.
class Deps extends InheritedNotifier<AppState> {
  const Deps({
    super.key,
    required this.app,
    required this.session,
    required this.locale,
    required this.theme,
    required super.child,
  }) : super(notifier: app);
  final AppState app;
  final Session session;
  final LocaleController locale;
  final ThemeController theme;

  static Deps of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Deps>()!;
  static Deps read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Deps>()!;
}

extension DepsX on BuildContext {
  AppState get app => Deps.of(this).app;
  AppState get appRead => Deps.read(this).app;
  ApiClient get api => Deps.read(this).app.api;
}

/// Everything a booking needs, filled step by step.
class BookingDraft {
  BookingDraft(this.service);
  final Service service;
  int? unitIndex;
  Address? address;
  DateTime? date;
  int? hour;
  String? couponId;
  String? methodId;
  QuoteAnswers answers = QuoteAnswers();

  /// Steps in this booking's flow (3 when the address step was skipped).
  int totalSteps = 4;

  int get listPrice => service.type == PricingType.fixed
      ? service.price!
      : (unitIndex == null ? 0 : service.units[unitIndex!].price);
  int get minutes => service.type == PricingType.fixed
      ? service.minutes!
      : (unitIndex == null ? 0 : service.units[unitIndex!].minutes);

  Json toJson() => {
    'service_code': service.code,
    'unit_index': unitIndex,
    'address_id': address!.id,
    'visit_date':
        '${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
    'start_hour': hour,
    'coupon_id': couponId,
    'payment_method_id': methodId,
    if (service.isQuote) 'answers': answers.toJson(),
  };
}
