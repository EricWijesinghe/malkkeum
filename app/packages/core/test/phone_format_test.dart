import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('11-digit mobile numbers are grouped 3-4-4', () {
    expect(formatPhone('01012345678'), '010-1234-5678');
    expect(formatPhone('010-1234-5678'), '010-1234-5678');
  });

  test('10-digit numbers are grouped 3-3-4', () {
    expect(formatPhone('0212345678'), '021-234-5678');
  });

  test('+82 numbers are converted to the domestic form', () {
    expect(formatPhone('+82 10 1234 5678'), '010-1234-5678');
  });

  test('unrecognised input is returned unchanged', () {
    expect(formatPhone('1234'), '1234');
    expect(formatPhone(''), '');
  });
}
