import 'package:core/core.dart';

/// The visit address with its district, e.g. "서울특별시 영등포구 여의대로 108 · 1203호".
/// The district is added only when the road address does not already name it (old bookings have no code).
String fullAddressLine(Json address) {
  final road = (address['road_address'] as String? ?? '').trim();
  final district = districtByCode(address['district_code'] as String? ?? '');
  final withDistrict = district == null || road.contains(district.ko)
      ? road
      : '${district.ko} $road';
  final detail = (address['detail'] as String? ?? '').trim();
  return [withDistrict, detail].where((s) => s.isNotEmpty).join(' · ');
}
