import 'dart:convert';

import 'api.dart';
import 'models.dart';

/// Where a tapped push opens. Keys come from backend realtime::notify payloads (booking_id, and
/// chat.message's `message` object carrying thread_id).
sealed class PushTarget {
  const PushTarget();
}

class BookingTarget extends PushTarget {
  const BookingTarget(this.bookingId);
  final String bookingId;

  @override
  bool operator ==(Object other) =>
      other is BookingTarget && other.bookingId == bookingId;
  @override
  int get hashCode => bookingId.hashCode;
}

class ChatTarget extends PushTarget {
  const ChatTarget(this.threadId);
  final String threadId;

  @override
  bool operator ==(Object other) =>
      other is ChatTarget && other.threadId == threadId;
  @override
  int get hashCode => threadId.hashCode;
}

/// FCM data values are strings, so the chat `message` object arrives as JSON text. Null = no route.
PushTarget? pushTargetFor(Map<String, dynamic> data) {
  final booking = data['booking_id'];
  if (booking is String && booking.isNotEmpty) return BookingTarget(booking);
  final raw = data['message'];
  final message = raw is String ? _decodeOrNull(raw) : raw;
  final thread = message is Map ? message['thread_id'] : null;
  if (thread is String && thread.isNotEmpty) return ChatTarget(thread);
  return null;
}

// A malformed push payload simply has no route; the notification still shows.
Object? _decodeOrNull(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

/// The chat thread with this id from the account's list (listPath: /chat/threads or /partner/threads).
Future<ChatThread?> findChatThread(
  ApiClient api,
  String listPath,
  String threadId,
) async {
  final list = await api.get(listPath) as List;
  return list
      .map((e) => ChatThread.fromJson(e as Json))
      .where((t) => t.id == threadId)
      .firstOrNull;
}
