import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors the counts examples in the change request (CR-5, CR-6, CR-7.1).
Service _counts({required List<UnitOption> units, int? maxEach, int bps = 0}) =>
    Service(
      code: 'test',
      type: PricingType.counts,
      units: units,
      maxEach: maxEach,
      multiDiscountBps: bps,
    );

const _wall = UnitOption('wall', 90, 79000);
const _stand = UnitOption('stand', 120, 119000);
const _twoInOne = UnitOption('two_in_one', 180, 179000);
const _ceiling = UnitOption('ceiling', 120, 139000);

void main() {
  group('counts pricing (server mirror)', () {
    test('aircon: 스탠드 2 + 벽걸이 1 is 285,300원 with 10% off, 5h30m', () {
      final s = _counts(units: [_wall, _stand, _twoInOne, _ceiling], bps: 1000);
      expect(s.countsPrice([1, 2, 0, 0]), 285300);
      expect(s.countsMinutes([1, 2, 0, 0]), 330);
    });

    test('disinfection: pest + sanitize is 162,000원 with 10% off', () {
      final s = _counts(
        units: const [
          UnitOption('pest', 90, 80000),
          UnitOption('mite_bedbug', 120, 90000),
          UnitOption('sanitize', 90, 100000),
          UnitOption('sick_house', 240, 300000),
        ],
        maxEach: 1,
        bps: 1000,
      );
      expect(s.isMultiSelect, isTrue);
      expect(s.countsPrice([1, 0, 1, 0]), 162000);
      expect(s.countsMinutes([1, 0, 1, 0]), 180);
    });

    test('window: 3 small + 2 large is 57,000원 and 1h35m, no discount', () {
      final s = _counts(
        units: const [
          UnitOption('small', 15, 9000),
          UnitOption('large', 25, 15000),
        ],
      );
      expect(s.isMultiSelect, isFalse);
      expect(s.countsPrice([3, 2]), 57000);
      expect(s.countsMinutes([3, 2]), 95);
    });

    test('minutes never fall below 60 once anything is picked', () {
      final s = _counts(units: const [UnitOption('small', 15, 9000)]);
      expect(s.countsMinutes([1]), 60);
      expect(s.countsMinutes([0]), 0);
      expect(s.countsPrice([0]), 0);
    });

    test('discount is round100(times_bps) and rounds half up', () {
      // 20,500 × 10% = 2,050 → 2,100 off → 18,400.
      final s = _counts(
        units: const [UnitOption('a', 60, 10250), UnitOption('b', 60, 10250)],
        bps: 1000,
      );
      expect(s.countsPrice([1, 1]), 18400);
    });

    test('a single item never gets the multi-item discount', () {
      final s = _counts(units: const [UnitOption('a', 60, 10000)], bps: 1000);
      expect(s.countsPrice([1]), 10000);
      expect(s.countsPrice([2]), 18000);
    });

    test('counts short of the option list are read as zero', () {
      final s = _counts(units: [_wall, _stand]);
      expect(s.countsPrice([1]), 79000);
      expect(s.countsMinutes([]), 0);
    });
  });

  group('counts parsing', () {
    test('service parses counts pricing with max_each and discount', () {
      final s = Service.fromJson({
        'code': 'disinfection',
        'pricing': {
          'type': 'counts',
          'max_each': 1,
          'multi_discount_bps': 1000,
          'units': [
            {'label_key': 'pest', 'minutes': 90, 'price': 80000},
          ],
        },
      });
      expect(s.type, PricingType.counts);
      expect(s.isCounts, isTrue);
      expect(s.isMultiSelect, isTrue);
      expect(s.countCap, 1);
      expect(s.multiDiscountBps, 1000);
      expect(s.fromPrice, 80000);
    });

    test('service without max_each allows up to kMaxCount per option', () {
      final s = Service.fromJson({
        'code': 'window',
        'pricing': {
          'type': 'counts',
          'units': [
            {'label_key': 'small', 'minutes': 15, 'price': 9000},
          ],
        },
      });
      expect(s.isMultiSelect, isFalse);
      expect(s.countCap, kMaxCount);
      expect(s.multiDiscountBps, 0);
    });

    test('booking reads unit_counts and defaults to empty', () {
      final counted = Booking.fromJson({
        'id': 'b1',
        'unit_counts': [1, 2],
      });
      final plain = Booking.fromJson({'id': 'b2'});
      expect(counted.unitCounts, [1, 2]);
      expect(plain.unitCounts, isEmpty);
    });

    test('legacy unit_index reads as one item of that option', () {
      final legacy = Booking.fromJson({'id': 'b3', 'unit_index': 1});
      expect(legacy.countsOf(3), [0, 1, 0]);
      expect(legacy.countsOf(2), [0, 1]);
    });

    test('sofa: 1~2인용 + 3인용 is 124,200원 with 10% off, 150 min', () {
      final s = _counts(
        units: const [
          UnitOption('seat_1_2', 60, 59000),
          UnitOption('seat_3', 90, 79000),
          UnitOption('seat_4_plus', 120, 99000),
          UnitOption('l_shape', 150, 119000),
        ],
        bps: 1000,
      );
      expect(s.countsPrice([1, 1, 0, 0]), 124200);
      expect(s.countsMinutes([1, 1, 0, 0]), 150);
    });

    test('mattress single option is 59,000원 for 60 min and one item', () {
      final s = _counts(units: const [UnitOption('mattress', 60, 59000)]);
      expect(s.countsPrice([1]), 59000);
      expect(s.countsMinutes([1]), 60);
      expect(s.countsPrice([0]), 0);
    });
  });
}
