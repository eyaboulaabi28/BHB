
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';

class NotificationService {
  final CreateNotificationUseCase _createNotificationUseCase;

  NotificationService(this._createNotificationUseCase);

  Future<void> send({
    required String title,
    required String message,
    String? userId,
    String? route,
  }) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      userId: userId,
      route: route,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _createNotificationUseCase(notification: notif);
  }
}
