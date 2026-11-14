import 'package:console/screens/catalog_counts.dart';
import 'package:flutter_test/flutter_test.dart';

const _aircon = [
  CountOption(label: 'wall', minutes: 90, price: 79000),
  CountOption(label: 'stand', minutes: 120, price: 119000),
];

void main() {
  group('countQuote', () {
    test(
      'two stand units and one wall unit get 10% off: 317,000 becomes 285,300',
      () {
        final q = countQuote(_aircon, const [2, 1], 1000);
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
      const small = [CountOption(label: 'x', minutes: 15, price: 9000)];
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
      const a = [CountOption(label: 'a', minutes: 60, price: 10050)];
      // 2 items: 20100 * 5% = 1005 -> rounds to 1000 off.
      final q = countQuote(a, const [2], 500);
      expect(q.off, 1000);
      expect(q.won, 19100);
    });
  });

  test('countOptionsOf reads the stored pricing JSON in order', () {
    final opts = countOptionsOf({
      'type': 'counts',
      'units': [
        {'label_key': 'wall', 'minutes': 90, 'price': 79000},
        {'label_key': 'stand', 'minutes': 120, 'price': 119000},
      ],
    });
    expect(opts.map((o) => o.label).toList(), ['wall', 'stand']);
    expect(opts[1].price, 119000);
  });
}
