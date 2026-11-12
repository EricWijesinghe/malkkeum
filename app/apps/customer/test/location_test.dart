import 'package:customer/location.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_location.dart';

Matcher _fails(LocationFailure reason) =>
    throwsA(isA<LocationException>().having((e) => e.reason, 'reason', reason));

void main() {
  group('koreanAddress', () {
    test('an Android full address line loses only the country name', () {
      expect(koreanAddress(gangnam), '서울특별시 강남구 테헤란로 152');
    });

    test('iOS parts are joined province to road, without repeats', () {
      const place = GeoPlace(
        countryCode: 'KR',
        country: '대한민국',
        administrativeArea: '서울특별시',
        locality: '서울특별시',
        subLocality: '강남구',
        thoroughfare: '테헤란로',
        subThoroughfare: '152',
        street: '테헤란로 152',
      );
      expect(koreanAddress(place), '서울특별시 강남구 테헤란로 152');
    });

    test('a road without a building number still gives an address', () {
      const place = GeoPlace(countryCode: 'kr', administrativeArea: '경기도', locality: '성남시', thoroughfare: '판교역로');
      expect(koreanAddress(place), '경기도 성남시 판교역로');
    });

    test('a place outside Korea gives no suggestion', () {
      const place = GeoPlace(countryCode: 'JP', administrativeArea: '東京都', thoroughfare: '丸の内', street: '丸の内 1');
      expect(koreanAddress(place), isNull);
    });

    test('a place that names no road gives no suggestion', () {
      expect(koreanAddress(const GeoPlace(countryCode: 'KR', administrativeArea: '서울특별시')), isNull);
      expect(koreanAddress(const GeoPlace(countryCode: 'KR', country: '대한민국', administrativeArea: '서울특별시', street: '대한민국 서울특별시')), isNull);
    });
  });

  group('suggestCurrentAddress', () {
    test('returns the address of the current position', () async {
      final device = FakeLocationDevice(fix: seoulFix);
      expect(await suggestCurrentAddress(device), '서울특별시 강남구 테헤란로 152');
    });

    test('location services off: fails before the permission prompt', () async {
      final device = FakeLocationDevice(enabled: false, fix: seoulFix);
      await expectLater(suggestCurrentAddress(device), _fails(LocationFailure.servicesOff));
      expect(device.permissionAsks, 0);
    });

    test('permission denied: fails without reading the position', () async {
      final device = FakeLocationDevice(granted: false, fix: seoulFix);
      await expectLater(suggestCurrentAddress(device), _fails(LocationFailure.denied));
      expect(device.positionReads, 0);
    });

    test('a fix that never arrives times out', () async {
      final device = FakeLocationDevice();
      await expectLater(
        suggestCurrentAddress(device, timeout: const Duration(milliseconds: 20)),
        _fails(LocationFailure.timeout),
      );
    });

    test('a geocoder error becomes "no address" and keeps its cause', () async {
      final cause = Exception('IO_ERROR');
      final device = FakeLocationDevice(fix: seoulFix, geocoderError: cause);
      await expectLater(
        suggestCurrentAddress(device),
        throwsA(isA<LocationException>().having((e) => e.reason, 'reason', LocationFailure.noAddress).having((e) => e.cause, 'cause', cause)),
      );
    });

    test('no usable place at the position is "no address"', () async {
      final device = FakeLocationDevice(fix: seoulFix, places: const [GeoPlace(countryCode: 'US', street: '1 Main St')]);
      await expectLater(suggestCurrentAddress(device), _fails(LocationFailure.noAddress));
    });
  });
}
