import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api.dart';
import 'push_registrar.dart';
import 'push_target.dart';

/// Matches the default channel id in AndroidManifest.xml (FCM background messages use it).
const _channelId = 'malkkeum_default';
const _channelName = '말끔';

/// Firebase push for both apps. Local builds have no google-services.json / GoogleService-Info.plist,
/// so every step checks for its config and turns push off instead of crashing.
class PushService {
  PushService._();

  static bool _firebaseReady = false;
  static final _local = FlutterLocalNotificationsPlugin();
  static final _taps = StreamController<PushTarget>.broadcast();
  static PushTarget? _pending;

  /// Notification taps while the app runs. Use [takePending] for a tap that opened the app.
  static Stream<PushTarget> get taps => _taps.stream;

  /// The tap that launched the app, if nobody was listening yet. Returns it once.
  static PushTarget? takePending() {
    final target = _pending;
    _pending = null;
    return target;
  }

  /// Call once before runApp.
  static Future<void> init() async {
    await _initLocal();
    _firebaseReady = await _initFirebase();
    if (!_firebaseReady) return;
    FirebaseMessaging.onBackgroundMessage(_onBackground);
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _emitFrom(m.data));
    final launch = await FirebaseMessaging.instance.getInitialMessage();
    if (launch != null) _emitFrom(launch.data);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
  }

  /// After sign-in: asks for notification permission, then registers this device's token and keeps it fresh.
  /// Also makes sign-out remove the token (Session.beforeLogout).
  static Future<void> start(ApiClient api) async {
    if (!_firebaseReady) return;
    final registrar = PushRegistrar(api: api, platform: Platform.isIOS ? 'ios' : 'android');
    api.session.beforeLogout = registrar.unregister;
    // Push setup must never break the app: a refused permission or a missing APNs token only means no push.
    try {
      await FirebaseMessaging.instance.requestPermission();
      if (Platform.isAndroid) {
        await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      }
      // shortcut: getToken/onTokenRefresh are deprecated in firebase_messaging 17 but still work; move to register()/onRegistered once tested on devices.
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await registrar.register(token);
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((t) => _registerQuietly(registrar, t));
    } catch (e) {
      debugPrint('push not registered: $e');
    }
  }

  static Future<void> _registerQuietly(PushRegistrar registrar, String token) async {
    try {
      await registrar.register(token);
    } catch (e) {
      debugPrint('push token refresh not saved: $e');
    }
  }

  static Future<void> _initLocal() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked through FirebaseMessaging.requestPermission, after sign-in.
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
      onDidReceiveNotificationResponse: (r) => _emitFromPayload(r.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(_channelId, _channelName, importance: Importance.high));
  }

  /// iOS: the plist is copied into the bundle by the Xcode "Firebase config" phase only when CI wrote it.
  /// Without it, configuring Firebase would crash the app, so it is skipped.
  static Future<bool> _initFirebase() async {
    if (Platform.isIOS) {
      final bundle = File(Platform.resolvedExecutable).parent.path;
      if (!File('$bundle/GoogleService-Info.plist').existsSync()) {
        debugPrint('push off: no GoogleService-Info.plist in this build');
        return false;
      }
    }
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('push off: Firebase not configured in this build ($e)');
      return false;
    }
  }

  /// Android does not show FCM notifications while the app is open, so show them locally.
  /// iOS shows them itself (see setForegroundNotificationPresentationOptions).
  static Future<void> _onForeground(RemoteMessage message) async {
    final n = message.notification;
    if (!Platform.isAndroid || n == null) return;
    await _local.show(
      id: message.messageId.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName, importance: Importance.high, priority: Priority.high),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _emitFrom(Map<String, dynamic> data) {
    final target = pushTargetFor(data);
    if (target != null) _emit(target);
  }

  static void _emitFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final data = jsonDecode(payload);
    if (data is Map<String, dynamic>) _emitFrom(data);
  }

  static void _emit(PushTarget target) {
    if (_taps.hasListener) {
      _taps.add(target);
    } else {
      _pending = target;
    }
  }
}

/// Top-level so the background isolate can run it. The OS shows notification messages itself.
@pragma('vm:entry-point')
Future<void> _onBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
}
