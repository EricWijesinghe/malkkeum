import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  test('service parsing and from-price', () {
    final unit = Service.fromJson({
      'code': 'bathroom',
      'pricing': {
        'type': 'unit',
        'units': [
          {'label_key': 'count_1', 'minutes': 120, 'price': 39000},
          {'label_key': 'count_2', 'minutes': 120, 'price': 52000},
        ],
      },
      'needs_preparation': true,
    });
    expect(unit.type, PricingType.unit);
    expect(unit.fromPrice, 39000);
    final quote = Service.fromJson({'code': 'move_in', 'pricing': {'type': 'quote'}});
    expect(quote.isQuote, isTrue);
    expect(quote.fromPrice, isNull);
  });

  test('coupon applicability mirrors server rules', () {
    final future = DateTime.now().add(const Duration(days: 3));
    final studio = Coupon(id: 'a', name: 'welcome_studio', amount: 10000, serviceCode: 'studio', expiresAt: future);
    final any = Coupon(id: 'b', name: 'welcome_any', amount: 5000, expiresAt: future);
    final used = Coupon(id: 'c', name: 'x', amount: 5000, expiresAt: future, usedBookingId: 'bk');
    final expired = Coupon(id: 'd', name: 'x', amount: 5000, expiresAt: DateTime.now().subtract(const Duration(minutes: 1)));
    expect(studio.appliesTo('bathroom'), isFalse);
    expect(studio.appliesTo('studio'), isTrue);
    expect(any.appliesTo('bathroom'), isTrue);
    expect(used.usable, isFalse);
    expect(expired.usable, isFalse);
  });

  test('won formatting per language', () {
    expect(formatWon(52000, 'ko'), '52,000원');
    expect(formatWon(52000, 'en'), '₩52,000');
  });

  test('quote answers serialise with server field names', () {
    final a = QuoteAnswers()
      ..cleaningType = 'after_interior'
      ..building = 'apartment'
      ..layout = 'three_rooms'
      ..duplex = false
      ..elevator = true
      ..bathrooms = 2;
    final j = a.toJson();
    expect(j['floor_3_or_higher'], isFalse);
    expect(j['bathrooms'], 2);
    expect(a.stepBasicDone && a.stepSpaceDone, isTrue);
  });

  test('every district code is a 5-digit Seoul code', () {
    expect(seoulDistricts.length, 25);
    expect(seoulDistricts.every((d) => RegExp(r'^11\d{3}$').hasMatch(d.code)), isTrue);
    expect(districtByCode('11680')?.ko, '강남구');
  });

  test('every language in the picker has generated translations', () {
    final generated = T.supportedLocales.map((l) => l.languageCode).toSet();
    for (final l in LocaleController.supported) {
      expect(generated, contains(l.languageCode));
    }
    expect(LocaleController.supported.length, 14);
  });
}
