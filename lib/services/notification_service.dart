import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([]);

  void addNotification(String title, String message) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  void init() {
    // Satisfy main.dart call
  }
}
