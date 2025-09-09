// lib/services/push_service.dart
import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher_string.dart'; // 👈 para abrir navegador
import '../main.dart' show navigatorKey;
import '../screens/webview_screen.dart';

// ===== Configura aquí tus dominios de app (se abrirán en WebView) =====
const _inAppAllowedHosts = <String>{
  'www.imaginariaestudio.com',
  'imaginariaestudio.com',
};

class PushService {
  static final _fcm = FirebaseMessaging.instance;
  static final _fln = FlutterLocalNotificationsPlugin();

  static const _channelId = 'imaginaria_default_channel';
  static const _channelName = 'Imaginaria';
  static const _channelDesc = 'Notificaciones generales';
static Future<void> debugShowLocal({
  required String title,
  required String body,
  String? link,
  bool browser = false,
}) async {
  final payload = _buildPayload(link: link, browser: browser);
  const android = AndroidNotificationDetails(
    _channelId, _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
  );
  await _fln.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(android: android),
    payload: payload,
  );
}
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // No navegues aquí (no hay UI). Solo logs si quieres.
    dev.log('[FCM][BG] ${message.messageId} data=${message.data}');
  }

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _fln.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload ?? '';
        final info = _extractPayloadInfo(payload);
        if (info == null) return;
        _routeByRule(info.link, forceExternal: info.browser);
      },
    );

    final androidImpl = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId, _channelName, description: _channelDesc, importance: Importance.high,
    ));

    final token = await _fcm.getToken();
    dev.log('[FCM] token = $token');
    _fcm.onTokenRefresh.listen((t) => dev.log('[FCM] token refresh = $t'));

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      dev.log('[FCM][FG] ${msg.messageId} data=${msg.data} notif=${msg.notification?.title}');
      if (msg.notification != null) {
        final link = _extractLinkFromMessage(msg.data);
        final browser = _extractBrowserFlag(msg.data);
        // Guardamos ambos en el payload para que, al tocar, sepamos qué hacer
        final payload = _buildPayload(link: link, browser: browser);
        await _showLocal(msg, payload: payload);
      }
    });

    final initialMsg = await _fcm.getInitialMessage();
    if (initialMsg != null) {
      _handleDeepLink(initialMsg);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);

    await _fcm.setAutoInitEnabled(true);
  }

  // ====== Noti local en foreground ======
  static Future<void> _showLocal(RemoteMessage msg, {String payload = ''}) async {
    final notif = msg.notification;
    if (notif == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notif.title ?? 'Imaginaria',
      notif.body ?? '',
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  // ====== Enrutado al tocar notificación ======
  static void _handleDeepLink(RemoteMessage msg) {
    final link = _extractLinkFromMessage(msg.data);
    final browser = _extractBrowserFlag(msg.data);
    if (link == null) return; // sin link, no navegamos
    _routeByRule(link, forceExternal: browser);
  }

  /// Aplica reglas:
  /// - Si forceExternal == true -> navegador externo
  /// - Si host pertenece a _inAppAllowedHosts -> WebView interno
  /// - En otro caso -> navegador externo
  static void _routeByRule(String link, {bool forceExternal = false}) {
    try {
      final uri = Uri.parse(link);
      final isHttp = uri.scheme == 'http' || uri.scheme == 'https';
      if (!isHttp) {
        // Esquema app custom: por ahora, abre externo (o podrías manejarlo distinto)
        _openExternal(link);
        return;
      }

      if (forceExternal) {
        _openExternal(link);
        return;
      }

      final host = (uri.host).toLowerCase();
      if (_inAppAllowedHosts.contains(host)) {
        _openInApp(link);
      } else {
        _openExternal(link);
      }
    } catch (e) {
      dev.log('[DEEPLINK][route] parse error: $e');
      _openExternal(link);
    }
  }

  static void _openInApp(String link) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;

  // Pasa Uri + hosts permitidos para abrir dentro del WebView
  nav.push(MaterialPageRoute(
    builder: (_) => WebViewScreen(
      initialUri: Uri.parse(link),
      title: 'Imaginaria',
      inAppHosts: _inAppAllowedHosts,
    ),
  ));
}


  static Future<void> _openExternal(String link) async {
    await launchUrlString(link, mode: LaunchMode.externalApplication);
  }

  // ====== Utilidades de extracción ======
  /// Busca la URL en varias claves habituales: link, url, deeplink
  static String? _extractLinkFromMessage(Map<String, dynamic> data) {
    final cand = [
      data['link'],
      data['url'],
      data['deeplink'],
      data['deep_link'],
    ];
    for (final v in cand) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Permite forzar navegador: data.browser=true|1|yes
  static bool _extractBrowserFlag(Map<String, dynamic> data) {
    final v = data['browser'];
    if (v == null) return false;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  /// Payload plano tipo: `link=https://...;browser=1`
  static String _buildPayload({String? link, bool browser = false}) {
    final parts = <String>[];
    if (link != null && link.isNotEmpty) parts.add('link=$link');
    if (browser) parts.add('browser=1');
    return parts.join(';');
  }

  /// Lee payload plano
  static _PayloadInfo? _extractPayloadInfo(String payload) {
    if (payload.isEmpty) return null;
    final chunks = payload.split(';');
    String? link;
    bool browser = false;
    for (final c in chunks) {
      final i = c.indexOf('=');
      if (i <= 0) continue;
      final k = c.substring(0, i).trim();
      final v = c.substring(i + 1).trim();
      if (k == 'link') link = v;
      if (k == 'browser') browser = (v == '1' || v.toLowerCase() == 'true');
    }
    if (link == null || link.isEmpty) return null;
    return _PayloadInfo(link, browser);
  }
}

class _PayloadInfo {
  final String link;
  final bool browser;
  const _PayloadInfo(this.link, this.browser);
}
