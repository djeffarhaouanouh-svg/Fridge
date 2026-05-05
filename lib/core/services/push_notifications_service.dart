import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'neon_service.dart';

class PushNotificationsService {
  PushNotificationsService._();
  static final PushNotificationsService instance = PushNotificationsService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    await _configureLocalNotifications();
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken.isNotEmpty) {
        await _saveToken(newToken);
      }
    });

    FirebaseMessaging.onMessage.listen((message) async {
      await _showForegroundNotification(message);
    });

    _initialized = true;
  }

  Future<void> _configureLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(initSettings);

    final androidPlatform = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlatform?.createNotificationChannel(
      const AndroidNotificationChannel(
        'fridge_default',
        'Fridge notifications',
        description: 'Notifications principales de Fridge',
        importance: Importance.high,
      ),
    );
  }

  Future<void> _saveToken(String token) async {
    final platform = _platformName();
    await NeonService().upsertPushToken(
      token: token,
      platform: platform,
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title ?? 'Fridge',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fridge_default',
          'Fridge notifications',
          channelDescription: 'Notifications principales de Fridge',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
