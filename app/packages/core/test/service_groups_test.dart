import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row(String code, {int order = 0, bool active = true}) => {
  'code': code,
  'title': {'ko': '$code 한글', 'en': code},
  'sort_order': order,
  'active': active,
  'chooser': 'list',
  'icon': 'svc_$code',
  'badge': null,
  'services': ['s_$code'],
};

void main() {
  test('missing groups fall back to the four built-in groups', () {
    expect(parseServiceGroups({}).map((g) => g.code), [
      'moving',
      'living',
      'appliance',
      'disinfection',
    ]);
    expect(parseServiceGroups({'groups': []}), defaultServiceGroups);
  });

  test('server groups are sorted and inactive ones dropped', () {
    final groups = parseServiceGroups({
      'groups': [
        _row('b', order: 2),
        _row('a', order: 1),
        _row('off', order: 0, active: false),
      ],
    });
    expect(groups.map((g) => g.code), ['a', 'b']);
    expect(groups.first.titleFor('en'), 'a');
    expect(groups.first.titleFor('ja'), 'a 한글');
  });

  test('a malformed row throws so the caller can fall back', () {
    expect(
      () => parseServiceGroups({
        'groups': [
          {'code': 'x'},
        ],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('home type codes round trip and unknown codes give null', () {
    expect(MoveHome.fromCode('apartment'), MoveHome.apartment);
    expect(MoveHome.fromCode('villa_house'), MoveHome.villaHouse);
    expect(MoveHome.fromCode('etc'), isNull);
    expect(MoveHome.fromCode(null), isNull);
  });
}
