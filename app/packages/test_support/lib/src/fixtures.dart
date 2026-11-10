import 'package:core/core.dart';

/// JSON builders shaped exactly like the API responses the app parses (see packages/core/lib/src/models.dart).
/// Defaults mirror the backend default catalogue (backend/crates/domain/src/catalog.rs).

const catalogCodes = ['studio', 'kitchen', 'bathroom', 'mattress', 'aircon', 'sofa', 'move_out', 'move_in'];

/// Expected list price shown on the home tile ("from" price = cheapest unit).
const catalogFromPrice = {
  'studio': 45000,
  'kitchen': 45000,
  'bathroom': 39000,
  'mattress': 59000,
  'aircon': 79000,
  'sofa': 59000,
};

Json _units(String code, List<(String, int, int)> units, {bool prep = true, int? maxPyeong}) => {
      'code': code,
      'pricing': {
        'type': 'unit',
        'units': [
          for (final (key, minutes, price) in units) {'label_key': key, 'minutes': minutes, 'price': price},
        ],
      },
      'needs_preparation': prep,
      'max_pyeong': maxPyeong,
      'content': <String, dynamic>{},
    };

Json serviceJson(String code) => switch (code) {
      'studio' => {
          'code': 'studio',
          'pricing': {'type': 'fixed', 'price': 45000, 'minutes': 120},
          'needs_preparation': true,
          'max_pyeong': 10,
          'content': <String, dynamic>{},
        },
      'kitchen' => {
          'code': 'kitchen',
          'pricing': {'type': 'fixed', 'price': 45000, 'minutes': 120},
          'needs_preparation': true,
          'max_pyeong': null,
          'content': <String, dynamic>{},
        },
      'bathroom' => _units('bathroom', [('count_1', 120, 39000), ('count_2', 120, 52000), ('count_3', 180, 69000), ('count_4', 240, 84000)]),
      'mattress' => _units('mattress', [('count_1', 60, 59000), ('count_2', 90, 99000), ('count_3', 120, 139000), ('count_4', 150, 175000)], prep: false),
      'aircon' => _units('aircon', [('wall', 90, 79000), ('stand', 120, 119000), ('two_in_one', 180, 179000), ('ceiling', 120, 139000)], prep: false),
      'sofa' => _units('sofa', [('seat_1_2', 60, 59000), ('seat_3', 90, 79000), ('seat_4_plus', 120, 99000), ('l_shape', 150, 119000)], prep: false),
      _ => {
          'code': code,
          'pricing': {'type': 'quote'},
          'needs_preparation': false,
          'max_pyeong': null,
          'content': <String, dynamic>{},
        },
    };

List<Json> catalogJson() => [for (final c in catalogCodes) serviceJson(c)];

Json addressJson({
  String id = 'addr-1',
  String kind = 'home',
  String label = '우리집',
  String roadAddress = '서울특별시 강남구 테헤란로 1',
  String detail = '101동 1001호',
  String districtCode = '11680',
  int sizePyeong = 25,
}) =>
    {
      'id': id,
      'kind': kind,
      'label': label,
      'road_address': roadAddress,
      'detail': detail,
      'district_code': districtCode,
      'size_pyeong': sizePyeong,
    };

Json couponJson({
  required String id,
  required String name,
  required int amount,
  String? serviceCode,
  DateTime? expiresAt,
  String? usedBookingId,
}) =>
    {
      'id': id,
      'name': name,
      'amount': amount,
      'service_code': serviceCode,
      'expires_at': (expiresAt ?? DateTime.now().add(const Duration(days: 30))).toUtc().toIso8601String(),
      'used_booking_id': usedBookingId,
    };

Json paymentMethodJson({String id = 'pm-1', String provider = 'card', String displayName = '신한 1234'}) => {
      'id': id,
      'provider': provider,
      'display_name': displayName,
    };

/// `yyyy-MM-dd` as the API sends visit dates.
String isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Booking status codes follow the app: 0..2 active, 3 done. Tests pass them explicitly.
Json bookingJson({
  String id = 'bk-1',
  String number = 'B-20260101-0001',
  String serviceCode = 'studio',
  int status = 0,
  DateTime? visitDate,
  int startHour = 9,
  int? unitIndex,
  int? minutes = 120,
  int? estimate,
  int? finalPrice,
  int? listPrice,
  int? deposit,
  int discount = 0,
  int paidAmount = 0,
  bool balancePaid = false,
  Json? answers,
  Json? address,
  String? threadId,
  Json? reschedule,
  bool reviewed = false,
}) =>
    {
      'id': id,
      'number': number,
      'service_code': serviceCode,
      'status': status,
      'visit_date': isoDay(visitDate ?? DateTime.now().add(const Duration(days: 3))),
      'start_hour': startHour,
      'unit_index': unitIndex,
      'minutes': minutes,
      'estimate': estimate,
      'final_price': finalPrice,
      'list_price': listPrice,
      'deposit': deposit,
      'discount': discount,
      'paid_amount': paidAmount,
      'balance_paid': balancePaid,
      'answers': answers,
      'address': address ?? addressJson(),
      'district_code': '11680',
      'thread_id': threadId,
      'reschedule': reschedule,
      'reviewed': reviewed,
      'photos': {'before': <String>[], 'after': <String>[]},
      'visit_notes': <String, dynamic>{},
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'completed_at': null,
    };

Json threadJson({
  String id = 'th-1',
  String topic = 'studio',
  String? bookingId,
  int unreadMember = 0,
  int unreadStaff = 0,
  Json? lastMessage,
}) =>
    {
      'id': id,
      'topic': topic,
      'booking_id': bookingId,
      'unread_member': unreadMember,
      'unread_staff': unreadStaff,
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      'last_message': lastMessage,
      'user_id': 'user-1',
      'pro_id': null,
    };

/// `kind` is one of text | system | card | quote | photo; `body` shape depends on it.
Json chatMessageJson({
  required String id,
  String threadId = 'th-1',
  String sender = 'staff',
  required String kind,
  required Json body,
}) =>
    {
      'id': id,
      'thread_id': threadId,
      'sender': sender,
      'kind': kind,
      'body': body,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

Json slotJson(int startHour, {bool available = true}) => {'start_hour': startHour, 'available': available};

/// Every hour the schedule screen asks about, all open.
List<Json> openSlots() => [for (final h in const [8, 9, 13, 14]) slotJson(h)];

Json contentJson({
  String id = 'c-1',
  String kind = 'notice',
  Map<String, String> title = const {'ko': '공지', 'en': 'Notice'},
  String? link,
}) =>
    {
      'id': id,
      'kind': kind,
      'title': title,
      'link': link,
      'image_url': null,
      'body': <String, dynamic>{},
    };
