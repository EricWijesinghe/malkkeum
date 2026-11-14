import 'package:console/screens/catalog.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

Json _group(
  String code,
  String ko,
  String icon,
  List<String> services, {
  String chooser = 'list',
  Json? config,
}) => {
  'code': code,
  'title': {'ko': ko, 'en': code},
  'sort_order': 0,
  'active': true,
  'icon': icon,
  'chooser': chooser,
  'services': services,
  'badge': null,
  'config': config ?? <String, Object?>{},
};

Json _service(String code, String name) => {
  'code': code,
  'active': true,
  'content': {'name': name},
};

final _moving = _group(
  'moving',
  '이사·입주 청소',
  'svc_move',
  ['move_in', 'move_out'],
  chooser: 'move',
  config: {
    'build_age': {'new': 'move_in', 'old': 'move_out'},
    'home_types': ['apartment'],
  },
);
final _living = _group('living', '거주 청소', 'svc_bathroom', [
  'bathroom',
  'kitchen',
]);
final _appliance = _group('appliance', '가전·가구 청소', 'svc_aircon', ['aircon']);

final _services = [
  _service('move_in', '입주 청소'),
  _service('move_out', '이사 청소'),
  _service('bathroom', '화장실 청소'),
  _service('kitchen', '주방 청소'),
  _service('aircon', '에어컨 청소'),
];

Future<FakeApi> _stock(WidgetTester tester, {List<Json>? groups}) async {
  final fake = FakeApi()
    ..reply('GET', '/admin/service-groups', {
      'groups': groups ?? [_moving, _living, _appliance],
    })
    ..reply('GET', '/admin/services', _services)
    ..reply('PUT', '/admin/service-groups/moving', {'ok': true})
    ..reply('PUT', '/admin/service-groups/living', {'ok': true});
  final env = await TestEnv.create(fake: fake, role: 'staff_admin');
  await pumpConsoleScreen(tester, env, const GroupsTab());
  await settle(tester);
  return fake;
}

/// Scrolls the dialog to [finder] and taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  final t = koT;

  testWidgets('a move tile with no home size choice is refused and not sent', (
    tester,
  ) async {
    final fake = await _stock(tester);
    await _tap(tester, find.text('이사·입주 청소'));
    await _tap(tester, find.widgetWithText(FilterChip, t.cgHomeApartment));
    await _tap(tester, find.widgetWithText(FilledButton, t.save));

    expect(find.text(t.cgGroupErrMove), findsOneWidget);
    expect(fake.callsTo('PUT', '/admin/service-groups/moving'), isEmpty);
  });

  testWidgets('a list tile saves its members in the order the owner set', (
    tester,
  ) async {
    final fake = await _stock(tester);
    await _tap(tester, find.text('거주 청소'));
    await _tap(tester, find.byTooltip(t.cntMoveUp).last);
    await _tap(tester, find.widgetWithText(FilledButton, t.save));

    final put = fake.lastCall('PUT', '/admin/service-groups/living');
    expect(put, isNotNull);
    expect(put!.json['services'], ['kitchen', 'bathroom']);
    expect(put.json['chooser'], 'list');
    expect(put.json['config'], <String, Object?>{});
  });

  testWidgets(
    'a service already in another tile is shown as taken and cannot be picked',
    (tester) async {
      await _stock(tester);
      await _tap(tester, find.text('거주 청소'));
      expect(find.text(t.cgMemberOtherGroup('가전·가구 청소')), findsOneWidget);
      final row = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, '에어컨 청소'),
      );
      expect(row.onChanged, isNull);
    },
  );
}
