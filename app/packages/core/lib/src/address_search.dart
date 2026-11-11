import 'api.dart';

/// One road-address result from the server's juso.go.kr proxy.
class AddressHit {
  const AddressHit({required this.road, required this.jibun, required this.zip, required this.building});
  final String road;
  final String jibun;
  final String zip;
  final String building;

  factory AddressHit.fromJson(Map<String, dynamic> j) => AddressHit(
    road: j['road_address'] as String? ?? '',
    jibun: j['jibun_address'] as String? ?? '',
    zip: j['zip_code'] as String? ?? '',
    building: j['building_name'] as String? ?? '',
  );
}

/// Road-address search over the backend proxy. Throws [ApiException] (e.g. 503 when no key is set).
Future<List<AddressHit>> searchAddresses(ApiClient api, String query, {int page = 1}) async {
  final r = await api.get('/address/search', query: {'q': query.trim(), 'page': '$page'}) as Map<String, dynamic>;
  return [for (final h in r['results'] as List) AddressHit.fromJson(h as Map<String, dynamic>)];
}

/// Whether the server can search addresses. Read once per screen; a failed read counts as off.
Future<bool> addressSearchEnabled(ApiClient api) async {
  try {
    final r = await api.get('/features') as Map<String, dynamic>;
    return r['address_search'] == true;
  } on Object {
    return false;
  }
}
