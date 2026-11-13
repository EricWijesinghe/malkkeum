import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Customer data the whole app reads: profile, catalogue, addresses, coupons, methods, unread.
class AppState extends ChangeNotifier {
  AppState(this.api, this.realtime, {JsonCache? cache, Analytics? analytics, this.startPush = PushService.start})
    : cache = cache ?? JsonCache(),
      analytics = analytics ?? Analytics.off() {
    realtime.events.listen(_onEvent);
  }

  final ApiClient api;
  final Realtime realtime;
  final JsonCache cache;
  final Analytics analytics;

  /// Registers this device for push under the signed-in account (tests pass a fake).
  final Future<void> Function(ApiClient api) startPush;

  /// Analytics follow the server's marketing consent. Any failure leaves analytics off.
  Future<void> syncAnalyticsConsent() async {
    final epoch = _epoch;
    try {
      final s = await api.get('/me/consents') as Json;
      if (epoch != _epoch) return;
      final items = (s['items'] as List).cast<Json>();
      analytics.setConsent(items.any((i) => i['kind'] == 'marketing' && i['granted'] == true));
    } on Object {
      analytics.setConsent(false);
    }
  }

  /// Bumped by [reset]: a response that started under the previous account is dropped.
  int _epoch = 0;

  /// Sign-out or account switch: forgets everything of the last account (the public catalogue stays)
  /// and turns analytics off until the next account's consent is read.
  void reset() {
    _epoch++;
    name = '';
    phone = '';
    email = null;
    logins = const [];
    joinedAt = null;
    points = null;
    addresses = const [];
    coupons = const [];
    methods = const [];
    unreadChats = 0;
    bookingsVersion++;
    analytics.setConsent(false);
    notifyListeners();
  }

  String name = '';
  String phone = '';
  String? email;

  /// Social providers linked to this account (`kakao`, `naver`, `apple`, `google`), read-only.
  List<String> logins = const [];

  /// Sign-up day (`/me` created_at), local time; null when the server does not send it.
  DateTime? joinedAt;

  /// Points balance for the More counter. Null until it loads, or when the wallet is unreachable.
  int? points;
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
    // Disk restore never gates the network: a slow or stuck keystore must not hold up sign-in data.
    unawaited(restoreServices());
    await Future.wait([
      loadProfile(),
      loadServices(),
      loadAddresses(),
      loadCoupons(),
      loadMethods(),
      loadUnread(),
    ]);
    // A counter only: the wallet must never hold up or fail sign-in data.
    unawaited(loadPoints());
  }

  Future<void> loadPoints() async {
    final epoch = _epoch;
    try {
      final p = await api.get('/me/points') as Json;
      if (epoch != _epoch) return;
      points = (p['balance'] as num? ?? 0).toInt();
    } on Exception {
      // Shown as a dash; the wallet screen reports the actual error.
      if (epoch != _epoch) return;
      points = null;
    }
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final epoch = _epoch;
    final p = await api.get('/me') as Json;
    if (epoch != _epoch) return;
    name = p['name'] as String? ?? '';
    phone = p['phone'] as String? ?? '';
    email = p['email'] as String?;
    logins = ((p['logins'] as List?) ?? const []).cast<String>();
    joinedAt = DateTime.tryParse(p['created_at'] as String? ?? '')?.toLocal();
    notifyListeners();
  }

  /// Paints the last catalogue from disk before the network answers.
  Future<void> restoreServices() async {
    if (services.isNotEmpty) return;
    final cached = await cache.read('services');
    if (cached is! List || services.isNotEmpty) return; // the network won the race
    try {
      services = cached.map((e) => Service.fromJson(e as Json)).toList();
    } on Object {
      // Stale snapshot from an older schema: ignore it and wait for the network.
      return;
    }
    notifyListeners();
  }

  Future<void> loadServices() async {
    final raw = await api.get('/services') as List;
    services = raw.map((e) => Service.fromJson(e as Json)).toList();
    notifyListeners();
    unawaited(cache.write('services', raw));
  }

  Future<void> loadAddresses() async {
    final epoch = _epoch;
    final raw = await api.get('/me/addresses') as List;
    if (epoch != _epoch) return;
    addresses = raw.map((e) => Address.fromJson(e as Json)).toList();
    notifyListeners();
  }

  Future<void> loadCoupons() async {
    final epoch = _epoch;
    final raw = await api.get('/me/coupons') as List;
    if (epoch != _epoch) return;
    coupons = raw.map((e) => Coupon.fromJson(e as Json)).toList();
    notifyListeners();
  }

  Future<void> loadMethods() async {
    final epoch = _epoch;
    final raw = await api.get('/me/payment-methods') as List;
    if (epoch != _epoch) return;
    methods = raw.map((e) => PaymentMethod.fromJson(e as Json)).toList();
    notifyListeners();
  }

  Future<void> loadUnread() async {
    final epoch = _epoch;
    final raw = await api.get('/chat/threads') as List;
    if (epoch != _epoch) return;
    final threads = raw.map((e) => ChatThread.fromJson(e as Json));
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

  /// [billingKey] comes from PortOne's card registration page; the server verifies it before saving.
  Future<PaymentMethod> addMethod(String provider, String displayName, String billingKey) async {
    final r = await api.post('/me/payment-methods', {
      'provider': provider,
      'auth_key': billingKey,
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
