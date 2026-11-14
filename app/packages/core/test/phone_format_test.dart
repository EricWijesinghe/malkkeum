import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats an 11-digit mobile number as 3-4-4', () {
    expect(formatKoreanPhone('01012345678'), '010-1234-5678');
  });

  test('formats a 10-digit number as 3-3-4', () {
    expect(formatKoreanPhone('0112345678'), '011-234-5678');
  });

  test('drops existing hyphens and spaces before formatting', () {
    expect(formatKoreanPhone('010-1234 5678'), '010-1234-5678');
  });

  test('partial input formats as far as it can', () {
    expect(formatKoreanPhone('010'), '010');
    expect(formatKoreanPhone('0101'), '010-1');
    expect(formatKoreanPhone('01012345'), '010-123-45');
  });

  test('empty input stays empty', () {
    expect(formatKoreanPhone(''), '');
  });
}
