// Plain immutable models mirroring the API JSON. Hand-written: no codegen step.

typedef Json = Map<String, dynamic>;

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();
int? _int(Object? v) => (v as num?)?.toInt();

class UnitOption {
  const UnitOption(this.labelKey, this.minutes, this.price);
  final String labelKey;
  final int minutes;
  final int price;
  factory UnitOption.fromJson(Json j) => UnitOption(
    j['label_key'] as String,
    _int(j['minutes'])!,
    _int(j['price'])!,
  );
}

enum PricingType { fixed, unit, quote }

class Service {
  const Service({
    required this.code,
    required this.type,
    this.price,
    this.minutes,
    this.units = const [],
    this.needsPreparation = false,
    this.maxPyeong,
    this.content = const {},
  });
  final String code;
  final PricingType type;
  final int? price;
  final int? minutes;
  final List<UnitOption> units;
  final bool needsPreparation;
  final int? maxPyeong;
  final Json content;

  bool get isQuote => type == PricingType.quote;
  int? get fromPrice => switch (type) {
    PricingType.fixed => price,
    PricingType.unit =>
      units.isEmpty
          ? null
          : units.map((u) => u.price).reduce((a, b) => a < b ? a : b),
    PricingType.quote => null,
  };

  factory Service.fromJson(Json j) {
    final p = j['pricing'] as Json;
    final type = PricingType.values.byName(p['type'] as String);
    return Service(
      code: j['code'] as String,
      type: type,
      price: _int(p['price']),
      minutes: _int(p['minutes']),
      units: ((p['units'] as List?) ?? const [])
          .map((u) => UnitOption.fromJson(u as Json))
          .toList(),
      needsPreparation: j['needs_preparation'] as bool? ?? false,
      maxPyeong: _int(j['max_pyeong']),
      content: (j['content'] as Json?) ?? const {},
    );
  }
}

class Address {
  const Address({
    required this.id,
    required this.kind,
    required this.label,
    required this.roadAddress,
    required this.detail,
    required this.districtCode,
    required this.sizePyeong,
    this.household = const {},
  });
  final String id;
  final String kind;
  final String label;
  final String roadAddress;
  final String detail;
  final String districtCode;
  final int sizePyeong;

  /// Household profile saved with this address (pets, floor, parking ...). Empty when never filled in.
  final Json household;

  factory Address.fromJson(Json j) => Address(
    id: j['id'] as String,
    kind: j['kind'] as String,
    label: j['label'] as String,
    roadAddress: j['road_address'] as String,
    detail: j['detail'] as String? ?? '',
    districtCode: j['district_code'] as String,
    sizePyeong: _int(j['size_pyeong'])!,
    household: (j['household'] as Json?) ?? const {},
  );

  Json toInput() => {
    'kind': kind,
    'label': label,
    'road_address': roadAddress,
    'detail': detail,
    'district_code': districtCode,
    'size_pyeong': sizePyeong,
  };
}

class Coupon {
  const Coupon({
    required this.id,
    required this.name,
    required this.amount,
    this.serviceCode,
    required this.expiresAt,
    this.usedBookingId,
  });
  final String id;
  final String name;
  final int amount;
  final String? serviceCode;
  final DateTime expiresAt;
  final String? usedBookingId;

  bool get usable => usedBookingId == null && expiresAt.isAfter(DateTime.now());
  bool appliesTo(String code) =>
      usable && (serviceCode == null || serviceCode == code);

  factory Coupon.fromJson(Json j) => Coupon(
    id: j['id'] as String,
    name: j['name'] as String,
    amount: _int(j['amount'])!,
    serviceCode: j['service_code'] as String?,
    expiresAt: _date(j['expires_at'])!,
    usedBookingId: j['used_booking_id'] as String?,
  );
}

class PaymentMethod {
  const PaymentMethod(this.id, this.provider, this.displayName);
  final String id;
  final String provider;
  final String displayName;
  factory PaymentMethod.fromJson(Json j) => PaymentMethod(
    j['id'] as String,
    j['provider'] as String,
    j['display_name'] as String,
  );
}

class Booking {
  const Booking(this.j);
  final Json j;

  String get id => j['id'] as String;
  String get number => j['number'] as String;
  String get serviceCode => j['service_code'] as String;
  int? get unitIndex => _int(j['unit_index']);
  int get status => _int(j['status'])!;
  DateTime get visitDate => DateTime.parse(j['visit_date'] as String);
  int get startHour => _int(j['start_hour'])!;
  int? get minutes => _int(j['minutes']);
  Json get address => j['address'] as Json;
  int? get estimate => _int(j['estimate']);
  int? get finalPrice => _int(j['final_price']);
  int? get deposit => _int(j['deposit']);
  int? get listPrice => _int(j['list_price']);
  int get discount => _int(j['discount']) ?? 0;
  int get paidAmount => _int(j['paid_amount']) ?? 0;
  bool get balancePaid => j['balance_paid'] as bool? ?? false;
  bool get isQuote => j['answers'] != null;
  Json? get answers => j['answers'] as Json?;
  String? get teamName => j['team_name'] as String?;
  String? get proId => j['pro_id'] as String?;
  String? get threadId => j['thread_id'] as String?;
  Json get visitNotes => (j['visit_notes'] as Json?) ?? const {};
  Json? get reschedule => j['reschedule'] as Json?;
  List<String> get beforePhotos =>
      (((j['photos'] as Json?)?['before'] as List?) ?? const []).cast<String>();
  List<String> get afterPhotos =>
      (((j['photos'] as Json?)?['after'] as List?) ?? const []).cast<String>();
  bool get reviewed => j['reviewed'] as bool? ?? false;
  DateTime get createdAt => _date(j['created_at'])!;
  DateTime? get checkedInAt => _date(j['checked_in_at']);
  DateTime? get checkedOutAt => _date(j['checked_out_at']);
  bool get entryCodeSet => j['entry_code_set'] as bool? ?? false;
  List<dynamic> get emergency => (j['emergency'] as List?) ?? const [];
  DateTime? get completedAt => _date(j['completed_at']);
  DateTime get visitStart =>
      DateTime(visitDate.year, visitDate.month, visitDate.day, startHour);
  bool get isActive => status >= 0 && status < 3;

  /// Paid and confirmed, no team assigned yet (backend `BookingStatus::Confirmed`).
  bool get isConfirmed => status == 1;
  bool get balanceDue =>
      isQuote && status == 3 && !balancePaid && finalPrice != null;

  factory Booking.fromJson(Json j) => Booking(j);
}

class ChatThread {
  const ChatThread(this.j);
  final Json j;
  String get id => j['id'] as String;
  String get topic => j['topic'] as String;
  String? get bookingId => j['booking_id'] as String?;
  int get unreadMember => _int(j['unread_member']) ?? 0;
  int get unreadStaff => _int(j['unread_staff']) ?? 0;
  DateTime get lastMessageAt => _date(j['last_message_at'])!;
  Json? get lastMessage => j['last_message'] as Json?;
  String? get userId => j['user_id'] as String?;
  String? get proId => j['pro_id'] as String?;
  bool get aiPaused => j['ai_paused'] == true;
  factory ChatThread.fromJson(Json j) => ChatThread(j);
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.kind,
    required this.body,
    required this.createdAt,
  });
  final String id;
  final String threadId;
  final String sender;
  final String kind;
  final Json body;
  final DateTime createdAt;

  /// Written by the AI support agent (staff sender, body flag).
  bool get isAi => body['ai'] == true;

  factory ChatMessage.fromJson(Json j) => ChatMessage(
    id: j['id'] as String,
    threadId: j['thread_id'] as String,
    sender: j['sender'] as String,
    kind: j['kind'] as String,
    body: j['body'] as Json,
    createdAt: _date(j['created_at'])!,
  );
}

/// Answers from the move-in / move-out steps. Field names match the server enums.
class QuoteAnswers {
  String? cleaningType;
  String luggage = 'empty';
  String? building;
  String? layout;
  bool? duplex;
  int bathrooms = 1;
  int balconies = 0;
  bool? elevator;
  bool floor3OrHigher = false;

  /// Aircon unit `label_key` -> count added to the move clean; the server prices them from the catalog.
  Map<String, int> acAddons = {};

  bool get stepBasicDone =>
      building != null && layout != null && duplex != null;
  bool get stepSpaceDone => elevator != null;

  Json toJson() => {
    'cleaning_type': cleaningType,
    'luggage': luggage,
    'building': building,
    'layout': layout,
    'duplex': duplex,
    'bathrooms': bathrooms,
    'balconies': balconies,
    'elevator': elevator,
    'floor_3_or_higher': floor3OrHigher,
    'ac_addons': [
      for (final e in acAddons.entries)
        if (e.value > 0) {'unit': e.key, 'count': e.value},
    ],
  };
}

class ContentItem {
  const ContentItem(this.j);
  final Json j;
  String get id => j['id'] as String;
  String get kind => j['kind'] as String;
  String? get link => j['link'] as String?;
  String? get imageUrl => j['image_url'] as String?;
  Json get body => (j['body'] as Json?) ?? const {};

  /// Posting date; null only for rows from an older server that does not send it.
  DateTime? get createdAt => _date(j['created_at']);

  /// Content is stored per language; fall back to Korean.
  String title(String lang) => _pick(j['title'], lang);
  String text(String lang) => _pick(body['text'], lang);

  /// Banner art card: a small label over a big value ("웰컴 혜택" / "15,000원"). Empty without one.
  String cardLabel(String lang) => _pick(_card?['label'], lang);
  String cardValue(String lang) => _pick(_card?['value'], lang);
  Map<dynamic, dynamic>? get _card =>
      body['card'] is Map ? body['card'] as Map : null;
  // Missing language: English is the better bridge for foreign residents; Korean last.
  static String _pick(Object? v, String lang) => v is Map
      ? (v[lang] ?? v['en'] ?? v['ko'] ?? '') as String
      : (v as String? ?? '');
}
