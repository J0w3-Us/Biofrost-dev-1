// features/notifications/providers/notifications_provider.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.data = const {},
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final Map<String, dynamic> data;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        receivedAt: receivedAt,
        isRead: isRead ?? this.isRead,
        data: data,
      );
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
        NotificationsNotifier.new);

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    _listenFcm();
    return [];
  }

  void _listenFcm() {
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      add(AppNotification(
        id: msg.messageId ?? DateTime.now().toIso8601String(),
        title: n.title ?? 'Notificación',
        body: n.body ?? '',
        receivedAt: DateTime.now(),
        data: msg.data,
      ));
    });
  }

  void add(AppNotification n) => state = [n, ...state];

  void markRead(String id) {
    state =
        state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void clearAll() => state = [];

  int get unreadCount => state.where((n) => !n.isRead).length;
}

/// Badge count para la NavBar
final unreadNotificationsCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider.notifier).unreadCount,
);
