import 'package:customer/screens/web_return.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no hash means no web route (every mobile launch and plain /app/ visit)', () {
    expect(webHashRoute(Uri.parse('https://malkkeum.example/app/')), isNull);
  });

  test('booking deep link and payment return parse from the hash', () {
    final booking = webHashRoute(Uri.parse('https://malkkeum.example/app/#/booking/b-9'));
    expect(booking!.pathSegments, ['booking', 'b-9']);

    final back = webHashRoute(Uri.parse('https://malkkeum.example/app/#/pay-return?paymentId=ck-1&code=USER_CANCEL'));
    expect(back!.path, '/pay-return');
    expect(back.queryParameters['paymentId'], 'ck-1');
    expect(back.queryParameters['code'], 'USER_CANCEL');
  });
}
