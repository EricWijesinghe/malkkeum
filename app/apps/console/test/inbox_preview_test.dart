import 'package:console/screens/inbox.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ko = lookupT(const Locale('ko'));
  String won(int n) => '$n원';

  test('quote card preview shows the final price', () {
    final last = {
      'kind': 'quote',
      'body': {'final_price': 363000, 'deposit': 36300},
    };
    expect(threadPreview(ko, last, won), '견적 카드 · 363000원');
  });

  test('request card preview says it is a booking request card', () {
    final last = {
      'kind': 'card',
      'body': {'service_code': 'move_in'},
    };
    expect(threadPreview(ko, last, won), '예약 요청 카드');
  });

  test('customer line shows 이름 없음 for a blank name and a formatted phone', () {
    final th = ChatThread.fromJson({
      'id': 't1',
      'topic': 'move_in',
      'customer_name': '',
      'customer_phone': '01012345678',
    });
    expect(customerLine(ko, th), '이름 없음 · 010-1234-5678');
  });

  test('partner threads have no customer line', () {
    final th = ChatThread.fromJson({'id': 't2', 'topic': 'move_in'});
    expect(customerLine(ko, th), isNull);
  });

  test(
    'text messages keep their text and an empty thread previews nothing',
    () {
      expect(
        threadPreview(ko, {
          'kind': 'text',
          'body': {'text': '안녕하세요'},
        }, won),
        '안녕하세요',
      );
      expect(threadPreview(ko, null, won), '');
    },
  );
}
