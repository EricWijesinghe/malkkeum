import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ko = lookupT(const Locale('ko'));

  test('move-out standard is labelled 퇴거 청소, not the raw code', () {
    expect(cleaningTypeLabel(ko, 'standard'), '퇴거 청소');
  });

  test('an unanswered cleaning type is not shown as a real type', () {
    expect(cleaningTypeLabel(ko, null), ko.quoteUnknown);
    expect(cleaningTypeLabel(ko, 'lived_in_deep_clean'), '거주 중 대청소');
  });

  test('answer rows map every code to its Korean label', () {
    final rows = quoteAnswerRows(ko, {
      'home_type': 'apartment',
      'cleaning_type': 'standard',
      'building': 'apartment',
      'layout': 'two_rooms',
      'duplex': false,
      'bathrooms': 2,
      'balconies': 1,
      'elevator': false,
      'floor_3_or_higher': true,
      'ac_addons': [
        {'unit': 'wall', 'count': 2},
      ],
    });
    final map = {for (final (k, v) in rows) k: v};
    expect(map[ko.qaCleaningType], '퇴거 청소');
    expect(map[ko.buildingType], '아파트');
    expect(map[ko.qaLayout], '거실+방 2개');
    expect(map[ko.qaHomeType], '아파트');
    expect(map[ko.qaFloor], '3층 이상');
    expect(map[ko.dfDuplexTitle], '없음');
    expect(rows.any((r) => r.$2.contains('_')), isFalse);
  });

  test('floor row appears only without an elevator', () {
    final rows = quoteAnswerRows(ko, {
      'elevator': true,
      'floor_3_or_higher': true,
    });
    expect(rows.any((r) => r.$1 == ko.qaFloor), isFalse);
  });

  test(
    'estimate rows show the peak line and VAT so they add up to the total',
    () {
      final rows = estimateRows(ko, {
        'base': 300000,
        'extras': 0,
        'surcharge_bps': 0,
        'peak_bps': 1000,
        'peak': 30000,
        'before_vat': 330000,
        'addons': 0,
        'addon_discount_bps': 0,
        'total': 363000,
      }, (n) => '$n원');
      final map = {for (final (k, v) in rows) k: v};
      expect(map[ko.qaPeak], '+10.0% · 30000원');
      expect(map[ko.qaVat], '33000원');
      expect(map[ko.qaTotal], '363000원');
    },
  );
}
