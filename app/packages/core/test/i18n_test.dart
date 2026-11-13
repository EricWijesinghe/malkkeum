import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('slotRangeLabel', () {
    test('ko writes the period once, as in the design', () {
      expect(slotRangeLabel(9, 'ko'), '오전 9시~10시');
      expect(slotRangeLabel(13, 'ko'), '오후 1시~2시');
    });

    test('ko repeats the period across noon and midnight', () {
      expect(slotRangeLabel(11, 'ko'), '오전 11시~오후 12시');
      expect(slotRangeLabel(23, 'ko'), '오후 11시~오전 12시');
    });

    test('withPeriod false drops the period', () {
      expect(slotRangeLabel(8, 'ko', withPeriod: false), '8시~9시');
      expect(slotRangeLabel(11, 'ko', withPeriod: false), '11시~12시');
    });

    test('ja and zh use their hour pattern without a repeated period', () {
      for (final lang in ['ja', 'zh']) {
        final label = slotRangeLabel(9, lang);
        final parts = label.split('~');
        expect(parts, hasLength(2), reason: label);
        expect(parts[1], startsWith('10'), reason: label);
      }
    });

    test('other languages keep 24h', () {
      expect(slotRangeLabel(8, 'en'), '08:00~09:00');
      expect(slotRangeLabel(13, 'vi', hours: 2), '13:00~15:00');
      expect(slotRangeLabel(23, 'en'), '23:00~00:00');
    });
  });
}
