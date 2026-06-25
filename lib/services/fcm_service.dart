import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // The system tray displays the notification automatically for background
  // messages that include a `notification` block. Nothing else needed here.
  debugPrint('BG message: ${message.messageId}');
}

/// Wraps Firebase Messaging + local notifications and syncs the device token
/// with the backend so this device can receive alerts.
class FcmService {
  final ApiClient _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  String? _token;
  bool _initialised = false;

  /// Called when the user taps a notification carrying request data.
  void Function(Map<String, dynamic> data)? onMessageOpened;

  FcmService(this._api);

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications channel (Android) for foreground display.
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            onMessageOpened?.call(jsonDecode(payload) as Map<String, dynamic>);
          } catch (_) {}
        }
      },
    );

    const channel = AndroidNotificationChannel(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      description: AppConfig.notificationChannelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground: show a heads-up local notification.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Tapped while in background.
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      onMessageOpened?.call(m.data);
    });

    // Cold start from a notification tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onMessageOpened?.call(initial.data);
    }

    _messaging.onTokenRefresh.listen(_registerToken);
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConfig.notificationChannelId,
          AppConfig.notificationChannelName,
          channelDescription: AppConfig.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Fetch the device token and register it with the backend (after login).
  Future<void> syncToken() async {
    try {
      _token = await _messaging.getToken();
      if (_token != null) await _registerToken(_token!);
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.post('/fcm/register', body: {'token': token});
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }

  /// Unregister on logout so the device stops receiving this account's alerts.
  Future<void> unregister() async {
    if (_token == null) return;
    try {
      await _api.post('/fcm/unregister', body: {'token': _token});
    } catch (_) {}
  }
}
