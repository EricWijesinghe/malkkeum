import 'gen/app_localizations.dart';
import 'i18n.dart';
import 'models.dart';

/// Korean/English labels for the codes in a customer's quote answers. Shared by the customer
/// app (quote steps, request status) and the console quote desk so both read the same words.
String homeTypeLabel(T t, String? c) => switch (c) {
  'one_two_room' => t.homeType_one_two_room,
  'apartment' => t.homeType_apartment,
  'villa_house' => t.homeType_villa_house,
  _ => t.quoteUnknown,
};

String buildingLabel(T t, String? c) => switch (c) {
  'apartment' => t.building_apartment,
  'officetel' => t.building_officetel,
  'villa' => t.dfBldVillaHouse,
  'commercial' => t.building_commercial,
  'house' => t.building_house,
  'other' => t.building_other,
  _ => t.quoteUnknown,
};

String layoutLabel(T t, String? c) => switch (c) {
  'studio' => t.layout_studio,
  'one_and_half' => t.dfLayoutOneHalf,
  'two_rooms' => t.dfLayoutTwo,
  'three_rooms' => t.dfLayoutThree,
  'four_plus' => t.dfLayoutFour,
  _ => t.quoteUnknown,
};

String luggageLabel(T t, String? c) => switch (c) {
  'empty' => t.luggage_empty,
  'not_unpacked' => t.luggage_not_unpacked,
  'partly_unpacked' => t.luggage_partly_unpacked,
  'fully_lived_in' => t.luggage_fully_lived_in,
  'unknown' => t.luggage_unknown,
  _ => t.quoteUnknown,
};

/// Explicit per code: an unanswered or unknown code must not read as a real cleaning type.
String cleaningTypeLabel(T t, String? c) => switch (c) {
  'standard' => t.type_standard,
  'same_day_move' => t.type_same_day_move,
  'some_luggage_left' => t.type_some_luggage_left,
  'normal_move_in' => t.type_normal_move_in,
  'after_interior' => t.type_after_interior,
  'lived_in_deep_clean' => t.type_lived_in_deep_clean,
  _ => t.quoteUnknown,
};

/// Quote answers as ordered (label, value) rows in Korean, for staff screens.
/// Keys absent from [a] are skipped; floor only matters without an elevator.
List<(String, String)> quoteAnswerRows(T t, Json a) {
  String yesNo(Object? v) => v == true ? t.dfHas : t.dfNone;
  String? str(String k) => a[k] as String?;
  int? intOf(String k) => (a[k] as num?)?.toInt();
  final rows = <(String, String)>[
    if (str('home_type') != null)
      (t.qaHomeType, homeTypeLabel(t, str('home_type'))),
    if (a.containsKey('cleaning_type'))
      (t.qaCleaningType, cleaningTypeLabel(t, str('cleaning_type'))),
    if (a.containsKey('luggage'))
      (t.qaLuggage, luggageLabel(t, str('luggage'))),
    if (a.containsKey('building'))
      (t.buildingType, buildingLabel(t, str('building'))),
    if (a.containsKey('layout')) (t.qaLayout, layoutLabel(t, str('layout'))),
    if (a.containsKey('duplex')) (t.dfDuplexTitle, yesNo(a['duplex'])),
    if (intOf('bathrooms') != null)
      (t.bathroomsLabel, t.unit_count('${intOf('bathrooms')}')),
    if (intOf('balconies') != null)
      (t.balconiesLabel, t.unit_count('${intOf('balconies')}')),
    if (a.containsKey('elevator')) (t.dfElevatorTitle, yesNo(a['elevator'])),
    if (a['elevator'] == false)
      (
        t.qaFloor,
        a['floor_3_or_higher'] == true ? t.qaFloorHigh : t.qaFloorLow,
      ),
    if (a['ac_addons'] case final List<dynamic> addons when addons.isNotEmpty)
      (
        t.service('aircon'),
        [
          for (final u in addons.cast<Json>())
            '${t.unit(u['unit'] as String)} ${t.dfCountUnits('${u['count']}')}',
        ].join(', '),
      ),
  ];
  return rows;
}

/// Basis points as a percent number without a trailing ".0": 1000 -> "10", 550 -> "5.5".
String pctNumber(int bps) {
  final v = bps / 100;
  return v == v.truncateToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

/// Itemised estimate as (label, amount) rows, in the order the customer pays them. The VAT row
/// is derived as total minus add-ons minus pre-VAT, so it is a check on the server total: a
/// mismatch shows as a wrong VAT figure rather than being hidden.
List<(String, String)> estimateRows(T t, Json e, String Function(int) won) {
  int n(String k) => (e[k] as num? ?? 0).toInt();
  final vat = n('total') - n('addons') - n('before_vat');
  return [
    (t.cBase, won(n('base'))),
    (t.cExtras, won(n('extras'))),
    (t.cSurcharge, '+${pctNumber(n('surcharge_bps'))}%'),
    if (n('peak') > 0)
      (t.qaPeak, '+${pctNumber(n('peak_bps'))}% · ${won(n('peak'))}'),
    (t.cBeforeVat, won(n('before_vat'))),
    if (vat != 0) (t.qaVat, won(vat)),
    if (n('addons') > 0)
      (t.dfEstAddons(pctNumber(n('addon_discount_bps'))), won(n('addons'))),
    (t.qaTotal, won(n('total'))),
  ];
}
