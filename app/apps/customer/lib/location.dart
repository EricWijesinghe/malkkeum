import 'dart:async';
import 'dart:ui' show Locale;

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

/// How long one position fix may take before the form falls back to typed entry.
const locationTimeout = Duration(seconds: 10);

/// Why "use my current location" produced no address. Every reason leaves typed entry working.
enum LocationFailure { denied, servicesOff, timeout, noAddress }

class LocationException implements Exception {
  const LocationException(this.reason, [this.cause]);
  final LocationFailure reason;

  /// The platform error behind [reason], kept for logs.
  final Object? cause;

  @override
  String toString() => 'LocationException(${reason.name}${cause == null ? '' : ', $cause'})';
}

/// The part of a device geocoder result the address suggestion is built from.
class GeoPlace {
  const GeoPlace({
    this.countryCode = '',
    this.country = '',
    this.administrativeArea = '',
    this.locality = '',
    this.subLocality = '',
    this.thoroughfare = '',
    this.subThoroughfare = '',
    this.street = '',
  });
  final String countryCode;
  final String country;
  final String administrativeArea;
  final String locality;
  final String subLocality;
  final String thoroughfare;
  final String subThoroughfare;

  /// Android: the whole address line. iOS: road name and number only.
  final String street;
}

/// The device's location and geocoder, behind an interface so tests need no device.
abstract interface class LocationDevice {
  Future<bool> serviceEnabled();

  /// Whether the app may read the location; asks the OS prompt once if not decided yet.
  Future<bool> permissionGranted();

  Future<({double latitude, double longitude})> position();

  /// Places at a point, in Korean, best match first.
  Future<List<GeoPlace>> placesAt(double latitude, double longitude);
}

/// One Korean address line for [p], or null when the place is outside Korea or names no road.
String? koreanAddress(GeoPlace p) {
  if (p.countryCode.toUpperCase() != 'KR') return null;
  final street = p.street.trim();
  final area = p.administrativeArea.trim();
  // Android gives the full line ("대한민국 서울특별시 강남구 테헤란로 152"): use it without the country.
  if (area.isNotEmpty && street.contains(area)) {
    final country = p.country.trim();
    final line = country.isNotEmpty && street.startsWith(country) ? street.substring(country.length).trim() : street;
    return line == area ? null : line;
  }
  final road = p.thoroughfare.trim().isEmpty ? street : '${p.thoroughfare.trim()} ${p.subThoroughfare.trim()}'.trim();
  if (road.isEmpty) return null;
  final parts = <String>[];
  for (final part in [area, p.locality.trim(), p.subLocality.trim(), road]) {
    if (part.isNotEmpty && !parts.contains(part)) parts.add(part);
  }
  return parts.join(' ');
}

/// The address suggestion for where the device is now. Throws [LocationException] with the reason
/// when there is none; the caller shows it and keeps typed entry. Never saves anything.
Future<String> suggestCurrentAddress(LocationDevice device, {Duration timeout = locationTimeout}) async {
  if (!await device.serviceEnabled()) throw const LocationException(LocationFailure.servicesOff);
  if (!await device.permissionGranted()) throw const LocationException(LocationFailure.denied);
  final ({double latitude, double longitude}) at;
  try {
    at = await device.position().timeout(timeout);
  } on TimeoutException catch (e) {
    throw LocationException(LocationFailure.timeout, e);
  }
  final List<GeoPlace> places;
  try {
    places = await device.placesAt(at.latitude, at.longitude).timeout(timeout);
  } on Exception catch (e) {
    // No geocoder backend, no network, or no match: all mean "no suggestion", with the cause kept.
    throw LocationException(LocationFailure.noAddress, e);
  }
  final address = places.map(koreanAddress).nonNulls.firstOrNull;
  if (address == null) throw const LocationException(LocationFailure.noAddress);
  return address;
}

extension LocationLabels on T {
  String locationFailure(LocationFailure reason) => switch (reason) {
    LocationFailure.denied => locDenied,
    LocationFailure.servicesOff => locServicesOff,
    LocationFailure.timeout => locTimeout,
    LocationFailure.noAddress => locNoAddress,
  };
}

/// The geocoding plugin has Android and iOS implementations only, so the button shows only there.
bool get locationSupported =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// [LocationDevice] over the geolocator and geocoding plugins. Coordinates stay on the device:
/// the OS geocoder turns them into an address and nothing is sent to the Malkkeum server.
class PluginLocationDevice implements LocationDevice {
  const PluginLocationDevice();

  @override
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> permissionGranted() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  @override
  Future<({double latitude, double longitude})> position() async {
    final p = await Geolocator.getCurrentPosition();
    return (latitude: p.latitude, longitude: p.longitude);
  }

  @override
  Future<List<GeoPlace>> placesAt(double latitude, double longitude) async {
    final marks = await geocoding.Geocoding(
      locale: const Locale('ko', 'KR'),
    ).placemarkFromCoordinates(latitude, longitude);
    return [
      for (final m in marks)
        GeoPlace(
          countryCode: m.isoCountryCode ?? '',
          country: m.country ?? '',
          administrativeArea: m.administrativeArea ?? '',
          locality: m.locality ?? '',
          subLocality: m.subLocality ?? '',
          thoroughfare: m.thoroughfare ?? '',
          subThoroughfare: m.subThoroughfare ?? '',
          street: m.street ?? '',
        ),
    ];
  }
}
