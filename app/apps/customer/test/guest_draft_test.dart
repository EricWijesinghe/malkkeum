import 'package:core/core.dart';
import 'package:customer/guest_draft.dart';
import 'package:customer/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

BookingDraft _draft(String code) => BookingDraft(Service.fromJson(serviceJson(code)));

void main() {
  test('a saved quote comes back for the same service only, and clears on request', () async {
    final guest = GuestDraft(JsonCache(storage: FakeStorage()));
    final saved = _draft('move_in');
    saved.answers
      ..cleaningType = 'normal_move_in'
      ..building = 'apartment'
      ..duplex = true
      ..elevator = false
      ..acAddons = {'stand': 2};
    await guest.save(saved);

    final again = _draft('move_in');
    await guest.restore(again);
    expect(again.answers.cleaningType, 'normal_move_in');
    expect(again.answers.building, 'apartment');
    expect(again.answers.duplex, isTrue);
    expect(again.answers.elevator, isFalse);
    expect(again.answers.acAddons, {'stand': 2});

    final other = _draft('studio');
    await guest.restore(other);
    expect(other.answers.building, isNull, reason: 'another service never gets this draft');

    await guest.clear();
    final cleared = _draft('move_in');
    await guest.restore(cleared);
    expect(cleared.answers.building, isNull, reason: 'a cleared draft restores nothing');
  });
}
