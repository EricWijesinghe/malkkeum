import 'package:customer/screens/booking_address.dart';
import 'package:customer/screens/cancel_booking_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fullAddressLine', () {
    test('adds the district when the road address does not name it', () {
      final line = fullAddressLine({
        'road_address': '여의대로 108',
        'detail': '1203호',
        'district_code': '11560',
      });
      expect(line, '영등포구 여의대로 108 · 1203호');
    });

    test('does not repeat a district the road address already has', () {
      final line = fullAddressLine({
        'road_address': '서울특별시 영등포구 여의대로 108',
        'detail': '',
        'district_code': '11560',
      });
      expect(line, '서울특별시 영등포구 여의대로 108');
    });

    test('old bookings without a district code show the road address only', () {
      expect(
        fullAddressLine({'road_address': '테헤란로 123', 'detail': ''}),
        '테헤란로 123',
      );
    });
  });

  group('CancelPreview.fromJson', () {
    test('reads the server numbers and treats missing money as zero', () {
      final p = CancelPreview.fromJson({
        'can_cancel': true,
        'days_before': 5,
        'percent': 10,
        'paid': 36300,
        'fee': 3630,
        'refund': 32670,
      });
      expect(p.canCancel, isTrue);
      expect(p.percent, 10);
      expect(p.fee + p.refund, p.paid);
    });

    test('a free or closed cancel has no percent and zero fee', () {
      final p = CancelPreview.fromJson({'can_cancel': false});
      expect(p.canCancel, isFalse);
      expect(p.percent, isNull);
      expect(p.fee, 0);
      expect(p.refund, 0);
    });
  });
}
