// core/notifications/notification_service.dart — FCM + notificaciones locales
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance._showLocalNotification(message);
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _logger = Logger();

  static const _channelId = 'Biofrost_channel';
  static const _channelName = 'Auditoría Hub';

  Future<void> initialize() async {
    try {
      // Permisos — puede fallar si el dispositivo no tiene GMS
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handler background
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Configurar canal Android
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Inicializar plugin local
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(settings: initSettings);

      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        _logger.i('FCM foreground: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // Token FCM — SERVICE_NOT_AVAILABLE si GMS no responde (ej. Xiaomi sin GMS)
      try {
        final token = await _messaging.getToken();
        _logger.i('FCM Token: $token');
      } catch (fcmError) {
        _logger
            .w('FCM getToken no disponible (GMS ausente o sin red): $fcmError');
        // La app sigue funcionando sin push; el token se puede reintentar más tarde.
      }
    } catch (e) {
      _logger.e('NotificationService.initialize error: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Devuelve el FCM token actual para enviarlo al backend.
  /// Retorna null si Google Play Services no está disponible.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      _logger.w('FCM getToken falló: $e');
      return null;
    }
  }
}
