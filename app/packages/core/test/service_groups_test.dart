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

  test('malformed sort_order, badge or config throw FormatException', () {
    for (final bad in <Map<String, dynamic>>[
      {..._row('x'), 'sort_order': '1'},
      {..._row('x'), 'badge': 1},
      {..._row('x'), 'config': 'nope'},
    ]) {
      expect(
        () => parseServiceGroups({
          'groups': [bad],
        }),
        throwsFormatException,
      );
    }
  });

  test('home type codes round trip and unknown codes give null', () {
    expect(MoveHome.fromCode('apartment'), MoveHome.apartment);
    expect(MoveHome.fromCode('villa_house'), MoveHome.villaHouse);
    expect(MoveHome.fromCode('etc'), isNull);
    expect(MoveHome.fromCode(null), isNull);
  });
}
