
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
  Future<void> markAsRead(String id) async {
    return await sl<NotificationFirebaseService>().markAsRead(id);
  }
  @override
  Stream<int> unreadCount(String userId) {
    return sl<NotificationFirebaseService>()
        .unreadNotificationsCount(userId);
  }

  @override
  Future<Either> getAllNotifications1({required String userId, required String role}) async{
    return await sl<NotificationFirebaseService>().getAllNotifications1(userId: userId, role: role);
  }

  @override
  Future<Either> getAllNotifications({required String role}) async{
    return await sl<NotificationFirebaseService>().getAllNotifications(role: role);
  }
}
