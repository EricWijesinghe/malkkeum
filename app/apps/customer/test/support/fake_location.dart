import 'dart:async';

import 'package:customer/location.dart';

const gangnam = GeoPlace(
  countryCode: 'KR',
  country: '대한민국',
  administrativeArea: '서울특별시',
  subLocality: '강남구',
  thoroughfare: '테헤란로',
  subThoroughfare: '152',
  street: '대한민국 서울특별시 강남구 테헤란로 152',
);

/// A device whose answers the test chooses; counts how often the OS would have been asked.
class FakeLocationDevice implements LocationDevice {
  FakeLocationDevice({
    this.enabled = true,
    this.granted = true,
    this.fix,
    this.places = const [gangnam],
    this.geocoderError,
  });

  bool enabled;
  bool granted;

  /// Null means a fix that never arrives.
  ({double latitude, double longitude})? fix;
  List<GeoPlace> places;
  Exception? geocoderError;
  int permissionAsks = 0;
  int positionReads = 0;

  @override
  Future<bool> serviceEnabled() async => enabled;

  @override
  Future<bool> permissionGranted() async {
    permissionAsks++;
    return granted;
  }

  @override
  Future<({double latitude, double longitude})> position() {
    positionReads++;
    final f = fix;
    return f == null ? Completer<({double latitude, double longitude})>().future : Future.value(f);
  }

  @override
  Future<List<GeoPlace>> placesAt(double latitude, double longitude) async {
    final e = geocoderError;
    if (e != null) throw e;
    return places;
  }
}

const seoulFix = (latitude: 37.5006, longitude: 127.0364);
