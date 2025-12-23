
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/source/notification_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/notification_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  @override
  Future<void> createNotification(NotificationsModel notification) async {
    return await sl<NotificationFirebaseService>().createNotification(notification);
  }
  @override
  Future<Either> getAllNotifications() async {
    return await sl<NotificationFirebaseService>().getAllNotifications();

  }
  @override
  Future<void> markAsRead(String id) async {
    return await sl<NotificationFirebaseService>().markAsRead(id);
  }
}
