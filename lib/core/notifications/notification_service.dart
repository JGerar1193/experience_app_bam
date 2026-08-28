import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/ecommerce/presentation/screens/transactions_screen.dart';
import '../../firebase_options.dart';

// Canal de Android (obligatorio desde API 26)
const _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificaciones importantes',
  importance: Importance.high,
);

// Handler de background: corre en isolate separado, sin UI
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM [background] id=${message.messageId}');
}

class NotificationService {
  NotificationService._();

  // NavigatorKey global para navegar desde notificaciones
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final _messaging = FirebaseMessaging.instance;
  static final _localPlugin = FlutterLocalNotificationsPlugin();

  /// Inicializa todo: canal, plugin local, permisos, token y listeners.
  static Future<void> init() async {
    await _createChannel();
    await _initLocalPlugin();
    await _requestPermission();
    await _initToken();
    _listenForeground();
    _listenTapBackground();
  }

  // ── Canal Android ─────────────────────────────────────────────────────────

  static Future<void> _createChannel() async {
    await _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  // ── flutter_local_notifications ───────────────────────────────────────────

  static Future<void> _initLocalPlugin() async {
    await _localPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _handleRoute(response.payload),
    );
  }

  // ── Permisos ──────────────────────────────────────────────────────────────

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permiso: ${settings.authorizationStatus}');

    // Solo iOS: mostrar banner del sistema en foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Token ─────────────────────────────────────────────────────────────────

  static Future<void> _initToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // Escucha cambios: reinstalación, limpieza de datos, etc.
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
    debugPrint('FCM token guardado: ${token.substring(0, 20)}...');
  }

  /// Llama esto en el logout para evitar que lleguen notificaciones ajenas.
  static Future<void> deleteToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = await _messaging.getToken();
    if (uid != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(token)
          .delete();
    }
    await _messaging.deleteToken();
  }

  // ── Foreground ────────────────────────────────────────────────────────────

  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      _showLocalNotification(
        title: n.title ?? '',
        body: n.body ?? '',
        payload: jsonEncode(message.data),
      );
    });
  }

  static void _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: _channel.importance,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // ── Background tap ────────────────────────────────────────────────────────

  static void _listenTapBackground() {
    // App en background → usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRoute(jsonEncode(message.data));
    });
  }

  /// Llama esto al arrancar la app para el caso Terminated.
  static Future<void> checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      // Espera a que el Navigator esté montado
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleRoute(jsonEncode(message.data)),
      );
    }
  }

  // ── Notificación local de compra ─────────────────────────────────────────

  static void showPurchaseNotification(double total) {
    _showLocalNotification(
      title: '¡Compra confirmada!',
      body:
          'Tu pedido por \$${total.toStringAsFixed(2)} fue procesado exitosamente.',
      payload: jsonEncode({'route': 'transactions'}),
    );
  }

  // ── Navegación ────────────────────────────────────────────────────────────

  static void _handleRoute(String? payload) {
    if (payload == null) return;
    // No navegar si no hay sesión activa
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final route = data['route'] as String?;
      if (route == 'transactions') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: TransactionsScreen()),
          ),
        );
      }
    } catch (_) {}
  }
}
