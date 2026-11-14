import 'package:console/screens/catalog_groups_model.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

Json _group({
  String chooser = 'move',
  List<String> services = const ['move_in', 'move_out'],
  Json? config,
}) => {
  'code': 'moving',
  'title': {'ko': '이사·입주 청소', 'en': 'Move'},
  'sort_order': 0,
  'active': true,
  'icon': 'svc_move',
  'chooser': chooser,
  'services': services,
  'config':
      config ??
      {
        'build_age': {'new': 'move_in', 'old': 'move_out'},
        'home_types': ['apartment'],
      },
};

void main() {
  final t = koT;

  test('a move tile with both build-age services and a home type saves its questions', () {
    final d = GroupDraft.from(_group());
    expect(d.problem(t), isNull);
    final body = d.toBody();
    expect(body['chooser'], 'move');
    expect(body['services'], ['move_in', 'move_out']);
    expect(body['config'], {
      'build_age': {'new': 'move_in', 'old': 'move_out'},
      'home_types': ['apartment'],
    });
  });

  test('a move tile without a home size choice is refused', () {
    final d = GroupDraft.from(_group(config: {
      'build_age': {'new': 'move_in', 'old': 'move_out'},
      'home_types': <String>[],
    }));
    expect(d.problem(t), t.cgGroupErrMove);
  });

  test('a direct tile must hold exactly one service', () {
    final d = GroupDraft.from(_group(chooser: 'direct', services: ['aircon', 'sofa']));
    expect(d.problem(t), t.cgGroupErrDirect);
    d.members.removeLast();
    expect(d.problem(t), isNull);
    expect(d.toBody()['config'], <String, Object?>{});
  });

  test('titles and order are checked before saving', () {
    final d = GroupDraft.from(_group());
    d.titleKo = '   ';
    expect(d.problem(t), t.cgGroupErrTitle);
    d
      ..titleKo = '이사'
      ..order = 100;
    expect(d.problem(t), t.cgGroupErrOrder);
  });

  test('a list tile with no members is refused', () {
    final d = GroupDraft.from(_group(chooser: 'list', services: const []));
    expect(d.problem(t), t.cgGroupErrMembers);
  });

  test('server refusal codes map to Korean messages', () {
    expect(groupServerMessage(t, 'service_in_other_group'), t.cgGroupErrOtherGroup);
    expect(groupServerMessage(t, 'invalid_group_title'), t.cgGroupErrTitle);
    expect(groupServerMessage(t, 'something_else'), isNull);
  });
}
