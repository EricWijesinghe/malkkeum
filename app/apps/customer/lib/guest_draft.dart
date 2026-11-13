import 'package:core/core.dart';

import 'state.dart';

const guestDraftKey = 'guest.draft';

/// A quote's answers kept on the device across restarts. Only the service code and the answers are
/// stored, never an address: nothing that identifies a guest is written before sign-in.
class GuestDraft {
  GuestDraft(this._cache);
  final JsonCache _cache;

  Future<void> save(BookingDraft d) => _cache.write(guestDraftKey, {
    'service_code': d.service.code,
    'answers': d.answers.toJson(),
  });

  /// Fills [d]'s answers when the saved draft is for the same service. Anything missing or of the
  /// wrong type keeps its default, so an old snapshot cannot break the flow.
  Future<void> restore(BookingDraft d) async {
    final saved = await _cache.read(guestDraftKey);
    if (saved is! Json || saved['service_code'] != d.service.code) return;
    final answers = saved['answers'];
    if (answers is Json) _applyAnswers(d.answers, answers);
  }

  Future<void> clear() => _cache.clear(guestDraftKey);
}

void _applyAnswers(QuoteAnswers a, Json j) {
  a.cleaningType = _as<String>(j['cleaning_type']);
  a.luggage = _as<String>(j['luggage']) ?? a.luggage;
  a.building = _as<String>(j['building']);
  a.layout = _as<String>(j['layout']);
  a.duplex = _as<bool>(j['duplex']);
  a.bathrooms = _as<int>(j['bathrooms']) ?? a.bathrooms;
  a.balconies = _as<int>(j['balconies']) ?? a.balconies;
  a.elevator = _as<bool>(j['elevator']);
  a.floor3OrHigher = _as<bool>(j['floor_3_or_higher']) ?? false;
  a.acAddons = {
    for (final e in _as<List>(j['ac_addons']) ?? const [])
      if (e is Json && _as<String>(e['unit']) != null && _as<int>(e['count']) != null)
        e['unit'] as String: e['count'] as int,
  };
}

T? _as<T>(Object? v) => v is T ? v : null;
