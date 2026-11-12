import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/navigate.dart';

void main() {
  const address = '서울 강남구 테헤란로 123 4층';
  final options = navOptions(address);

  test('each map app opens its own scheme with the address as the search text', () {
    expect([for (final o in options) o.app.scheme], ['kakaomap', 'nmap', 'tmap']);
    expect(options[0].app.queryParameters['q'], address);
    expect(options[1].app.queryParameters['query'], address);
    expect(options[2].app.queryParameters['name'], address);
  });

  test('Naver needs the bundle id as appname', () {
    expect(options[1].app.queryParameters['appname'], 'com.malkkeum.partner');
  });

  test('every option has an https web fallback that carries the address', () {
    for (final o in options) {
      expect(o.web.scheme, 'https', reason: o.name);
    }
    expect(options[0].web.host, 'map.kakao.com');
    expect(options[1].web.pathSegments.last, address);
    expect(options[2].web.queryParameters['query'], address);
  });
}
