import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_review/in_app_review.dart';

/// Shows the OS review sheet once per install, after the customer's first reviewed booking.
/// The OS decides whether the sheet actually appears (quota, platform rules), so "not shown" is normal.
/// Never a custom "rate us?" dialog first: store policies forbid gating the OS prompt that way.
class StoreReview {
  StoreReview({
    required this.wasAsked,
    required this.markAsked,
    required this.isAvailable,
    required this.request,
  });

  /// Device wiring: flag in secure storage, platform review API.
  factory StoreReview.device({FlutterSecureStorage? storage}) {
    final s = storage ?? const FlutterSecureStorage();
    final review = InAppReview.instance;
    return StoreReview(
      wasAsked: () async => await s.read(key: _key) == '1',
      markAsked: () => s.write(key: _key, value: '1'),
      isAvailable: review.isAvailable,
      request: review.requestReview,
    );
  }

  static const _key = 'store_review_asked';

  final Future<bool> Function() wasAsked;
  final Future<void> Function() markAsked;
  final Future<bool> Function() isAvailable;
  final Future<void> Function() request;

  /// Marks the flag before asking, so a crash or a second review cannot ask twice.
  /// Failures are ignored on purpose: a review prompt must never show an error to the customer.
  Future<void> maybeAsk() async {
    try {
      if (await wasAsked()) return;
      await markAsked();
      if (await isAvailable()) await request();
    } catch (_) {
      // Non-critical UI nicety; the booking flow continues without it.
    }
  }
}
