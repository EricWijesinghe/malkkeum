import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'groups parse with titles, chooser, badge and members in owner order',
    () {
      final groups = serviceGroupsFrom({
        'groups': [
          {
            'code': 'living',
            'title': {'ko': '거주 청소', 'en': 'Home cleaning'},
            'sort_order': 1,
            'active': true,
            'icon': 'svc_bathroom',
            'chooser': 'list',
            'badge': 'HOT',
            'services': ['bathroom', 'kitchen'],
            'config': <String, Object?>{},
          },
          {
            'code': 'moving',
            'title': {'ko': '이사·입주 청소', 'en': 'Move'},
            'sort_order': 0,
            'active': true,
            'icon': 'svc_move',
            'chooser': 'move',
            'badge': null,
            'services': ['move_in', 'move_out'],
            'config': {
              'build_age': {'new': 'move_in', 'old': 'move_out'},
              'home_types': ['apartment'],
            },
          },
        ],
      });
      expect(groups.map((g) => g.code), ['moving', 'living']);
      expect(groups.first.title(korean: false), 'Move');
      expect(groups.last.title(korean: true), '거주 청소');
      expect(groups.last.badge, 'HOT');
      expect(groups.last.services, ['bathroom', 'kitchen']);
      expect(groups.first.config['home_types'], ['apartment']);
    },
  );

  test('a body without groups parses to an empty list', () {
    expect(serviceGroupsFrom(<String, dynamic>{}), isEmpty);
  });
}
