import 'package:console/screens/privacy_requests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the typed phone must match the stored one ignoring dashes', () {
    expect(samePhoneDigits('010-1234-5678', '01012345678'), isTrue);
    expect(samePhoneDigits('01012345679', '01012345678'), isFalse);
    expect(
      samePhoneDigits('', ''),
      isFalse,
      reason: 'an empty confirmation never passes',
    );
  });
}
