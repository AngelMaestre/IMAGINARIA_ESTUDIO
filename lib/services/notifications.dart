// lib/services/notifications.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'imaginaria_default',
    'General',
    description: 'Notificaciones generales de IMAGINARIA',
    importance: Importance.high,
  );

  static Future<void> init() async {
    await Firebase.initializeApp();

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((msg) async {
      final n = msg.notification;
      if (n != null && !Platform.isIOS) {
        await _local.show(
          n.hashCode,
          n.title,
          n.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: msg.data['route'],
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // TODO: navegación si quieres usar msg.data['route']
    });

    // Opcional: ver token en consola
    final token = await _messaging.getToken();
    debugPrint('FCM token => $token');

    await _messaging.subscribeToTopic('all');
  }
}
