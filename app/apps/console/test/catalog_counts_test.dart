import 'package:console/screens/catalog_counts.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

const _aircon = [
  CountOption(key: 'wall', label: '벽걸이', minutes: 90, price: 79000),
  CountOption(key: 'stand', label: '스탠드', minutes: 120, price: 119000),
];

Json _pricing({int? maxEach = 5, int bps = 1000}) => {
  'type': 'counts',
  'units': [
    {'label_key': 'wall', 'label': '벽걸이', 'minutes': 90, 'price': 79000},
    {'label_key': 'stand', 'minutes': 120, 'price': 119000},
  ],
  'max_each': maxEach,
  'multi_discount_bps': bps,
};

void main() {
  final t = koT;

  group('countQuote', () {
    test(
      'two stand units and one wall unit get 10% off: 317,000 becomes 285,300',
      () {
        final q = countQuote(_aircon, const [1, 2], 1000);
        expect(q.won, 285300);
        expect(q.off, 31700);
        expect(q.minutes, 330);
      },
    );

    test('a single item gets no discount', () {
      final q = countQuote(_aircon, const [1, 0], 1000);
      expect(q.won, 79000);
      expect(q.off, 0);
      expect(q.minutes, 90);
    });

    test('minutes never fall below the one-hour floor', () {
      const small = [
        CountOption(key: 'x', label: 'x', minutes: 15, price: 9000),
      ];
      final q = countQuote(small, const [1], 0);
      expect(q.minutes, 60);
      expect(q.won, 9000);
    });

    test('an empty basket costs nothing and takes no time', () {
      final q = countQuote(_aircon, const [0, 0], 1000);
      expect(q.won, 0);
      expect(q.minutes, 0);
      expect(q.off, 0);
    });

    test('discount rounds to the nearest 100 won', () {
      const a = [CountOption(key: 'a', label: 'a', minutes: 60, price: 10050)];
      // 2 items: 20100 * 5% = 1005 -> rounds to 1000 off.
      final q = countQuote(a, const [2], 500);
      expect(q.off, 1000);
      expect(q.won, 19100);
    });
  });

  test('countOptionsOf reads the stored key, label and order', () {
    final opts = countOptionsOf(_pricing());
    expect(opts.map((o) => o.key).toList(), ['wall', 'stand']);
    expect(opts.map((o) => o.label).toList(), ['벽걸이', 'stand']);
    expect(opts[1].price, 119000);
  });

  group('CountsDraft', () {
    test('a complete draft can be saved and keeps stable keys', () {
      final d = CountsDraft(_pricing());
      expect(d.problem(t), isNull);
      final out = d.toPricing();
      expect(out['type'], 'counts');
      expect(out['max_each'], 5);
      expect(out['multi_discount_bps'], 1000);
      expect((out['units'] as List)[0], {
        'label_key': 'wall',
        'label': '벽걸이',
        'minutes': 90,
        'price': 79000,
      });
    });

    test('renaming an option keeps its key', () {
      final d = CountsDraft(_pricing());
      d.rows[0].label.text = '벽걸이 소형';
      final unit = (d.toPricing()['units'] as List)[0] as Json;
      expect(unit['label_key'], 'wall');
      expect(unit['label'], '벽걸이 소형');
    });

    test('a new option gets a generated key that is never empty', () {
      expect(newCountKey(), startsWith('opt_'));
      expect(newCountKey().length, greaterThan(4));
    });

    test('no options, an empty name or a zero price cannot be saved', () {
      final none = CountsDraft({'type': 'counts', 'units': []});
      expect(none.problem(t), t.cntNeedOption);

      final unnamed = CountsDraft(_pricing());
      unnamed.rows[1].label.text = '  ';
      expect(unnamed.problem(t), t.cntNeedName);

      final free = CountsDraft(_pricing());
      free.rows[0].price.text = '0';
      expect(free.problem(t), t.cntNeedPrice);
    });

    test('the per-option cap must be 1 to 20 and the discount 0 to 50%', () {
      final cap = CountsDraft(_pricing());
      cap.maxEach.text = '21';
      expect(cap.problem(t), t.cntMaxEachInvalid);
      cap.maxEach.text = '0';
      expect(cap.problem(t), t.cntMaxEachInvalid);
      cap.maxEach.text = '1';
      expect(cap.problem(t), isNull);

      final pct = CountsDraft(_pricing());
      pct.discountPct.text = '51';
      expect(pct.problem(t), t.cntDiscountInvalid);
      pct.discountPct.text = '50';
      expect(pct.problem(t), isNull);
      expect(pct.toPricing()['multi_discount_bps'], 5000);
    });

    test('a blank cap is saved as no cap', () {
      final d = CountsDraft(_pricing(maxEach: null));
      expect(d.problem(t), isNull);
      expect(d.toPricing()['max_each'], isNull);
    });
  });
}
