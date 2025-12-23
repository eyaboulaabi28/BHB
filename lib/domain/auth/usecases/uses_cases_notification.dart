
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/repository/notification_repository.dart';

class CreateNotificationUseCase {
  final NotificationRepository _repo = sl<NotificationRepository>();

  Future<void> call({required NotificationsModel notification}) async {
    await _repo.createNotification(notification);
  }
}
class GetNotificationUseCase implements UseCase<Either, void> {
  @override
  Future<Either> call({void params}) async {
    return await sl<NotificationRepository>().getAllNotifications();
  }
}
class MarkNotificationAsReadUseCase {
  final NotificationRepository _repo = sl<NotificationRepository>();

  Future<void> call(String id) async {
    await _repo.markAsRead(id);
  }
}