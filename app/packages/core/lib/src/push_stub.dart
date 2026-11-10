import 'api.dart';
import 'push_target.dart';

/// Web has no push: same surface as push_io.dart, every call does nothing.
class PushService {
  PushService._();

  static Stream<PushTarget> get taps => const Stream.empty();

  static PushTarget? takePending() => null;

  static Future<void> init() async {}

  static Future<void> start(ApiClient api) async {}
}
