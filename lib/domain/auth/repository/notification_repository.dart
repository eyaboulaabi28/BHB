
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:dartz/dartz.dart';

abstract class NotificationRepository {
  Future<void> createNotification(NotificationsModel notification);
  Future<void> markAsRead(String id);
  Stream<int> unreadCount(String userId);
  Future<Either> getAllNotifications1({
    required String userId,
    required String role,
  });
  Future<Either> getAllNotifications({
    required String role,
  });
}
