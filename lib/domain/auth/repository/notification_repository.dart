
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:dartz/dartz.dart';

abstract class NotificationRepository {
  Future<void> createNotification(NotificationsModel notification);
  Future<Either> getAllNotifications();
  Future<void> markAsRead(String id);

}
