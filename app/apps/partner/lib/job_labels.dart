import 'package:core/core.dart';

/// Catalogue option order of each counts service (backend default_catalog). A booking's
/// unit_counts follow this order.
/// shortcut: fixed here, not read from the catalogue; a new counts service needs a row here.
const _countOptions = <String, List<String>>{
  'aircon': ['wall', 'stand', 'two_in_one', 'ceiling'],
  'sofa': ['seat_1_2', 'seat_3', 'seat_4_plus', 'l_shape'],
  'mattress': ['mattress'],
};

String _unitName(T t, String key) => switch (key) {
  'wall' => t.pUnitWall,
  'stand' => t.pUnitStand,
  'two_in_one' => t.pUnitTwoInOne,
  'ceiling' => t.pUnitCeiling,
  'seat_1_2' => t.pUnitSeat12,
  'seat_3' => t.pUnitSeat3,
  'seat_4_plus' => t.pUnitSeat4Plus,
  'l_shape' => t.pUnitLShape,
  'mattress' => t.pUnitMattress,
  _ => key,
};

/// "벽걸이 1 · 스탠드 2" for a job's counts; null when the job has none to show.
String? jobCountsLabel(T t, Json job) {
  final keys = _countOptions[job['service_code']];
  final counts = (job['unit_counts'] as List?)?.cast<num>();
  if (keys == null || counts == null) return null;
  final parts = [
    for (var i = 0; i < counts.length && i < keys.length; i++)
      if (counts[i] > 0) '${_unitName(t, keys[i])} ${counts[i]}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Home type a quote was answered with (원룸·투룸 / 아파트 / 빌라·주택); null for older quotes.
String? homeTypeLabel(T t, Json? answers) => switch (answers?['home_type']) {
  'one_two_room' => t.pHomeOneTwo,
  'apartment' => t.pHomeApartment,
  'villa_house' => t.pHomeVillaHouse,
  _ => null,
};
