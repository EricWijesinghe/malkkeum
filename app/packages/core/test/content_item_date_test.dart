import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createdAt reads the posting date from a notice row', () {
    final item = ContentItem({
      'id': 'n1',
      'kind': 'notice',
      'created_at': '2026-11-14T03:00:00Z',
    });
    expect(item.createdAt, isNotNull);
    expect(item.createdAt!.toUtc(), DateTime.utc(2026, 11, 14, 3));
  });

  test('createdAt is null when an older server sends no date', () {
    final item = ContentItem({'id': 'n1', 'kind': 'notice'});
    expect(item.createdAt, isNull);
  });
}
