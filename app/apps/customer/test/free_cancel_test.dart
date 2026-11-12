import 'package:customer/screens/booking_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final visit = DateTime(2026, 11, 20);

  test('deadline is two days before the visit', () {
    expect(freeCancelDeadline(visit, DateTime(2026, 11, 12, 15)), DateTime(2026, 11, 18));
  });

  test('deadline today still shows', () {
    expect(freeCancelDeadline(visit, DateTime(2026, 11, 18, 23, 59)), DateTime(2026, 11, 18));
  });

  test('deadline already past (booking inside the window) hides', () {
    expect(freeCancelDeadline(visit, DateTime(2026, 11, 19, 8)), isNull);
    expect(freeCancelDeadline(visit, DateTime(2026, 11, 20)), isNull);
  });
}
