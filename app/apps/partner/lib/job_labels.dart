import 'package:core/core.dart';

/// Catalogue option order of each counts service (backend default_catalog). A booking's
/// unit_counts follow this order.
/// shortcut: fixed here, not read from the catalogue; a new counts service needs a row here.
const _countOptions = <String, List<String>>{
  'aircon': ['wall', 'stand', 'two_in_one', 'ceiling'],
  'sofa': ['seat_1_2', 'seat_3', 'seat_4_plus', 'l_shape'],
  'mattress': ['mattress'],
  'window': ['window_small', 'window_large'],
  'disinfection': ['pest', 'mite_bedbug', 'sanitize', 'sick_house'],
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
  'window_small' => t.pUnitWindowSmall,
  'window_large' => t.pUnitWindowLarge,
  'pest' => t.pUnitPest,
  'mite_bedbug' => t.pUnitMiteBedbug,
  'sanitize' => t.pUnitSanitize,
  'sick_house' => t.pUnitSickHouse,
  _ => key,
};

/// Counts per option in catalogue order. Older aircon bookings carry only answers.ac_addons
/// (one unit/count entry per option), so those map onto the same order.
List<num>? _jobCounts(Json job, List<String> keys) {
  final counts = (job['unit_counts'] as List?)?.cast<num>();
  if (counts != null) return counts;
  final answers = job['answers'];
  final addons = answers is Map ? answers['ac_addons'] : null;
  if (addons is! List || addons.isEmpty) return null;
  final byUnit = <String, num>{
    for (final a in addons.whereType<Map>())
      if (a['unit'] is String) a['unit'] as String: (a['count'] as num?) ?? 0,
  };
  return [for (final k in keys) byUnit[k] ?? 0];
}

/// "벽걸이 1 · 스탠드 2" for a job's counts; null when the job has none to show.
String? jobCountsLabel(T t, Json job) {
  final keys = _countOptions[job['service_code']];
  if (keys == null) return null;
  final counts = _jobCounts(job, keys);
  if (counts == null) return null;
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
