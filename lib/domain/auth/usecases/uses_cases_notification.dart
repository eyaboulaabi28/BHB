
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
class GetNotificationUseCase implements UseCase<Either, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotificationUseCase(this.repository);

  @override
  Future<Either> call({GetNotificationsParams? params}) async {
    if (params == null) {
      throw ArgumentError('params cannot be null');
    }
    return await repository.getAllNotifications(role: params.role);
  }
}


class GetNotificationsParams {
  final String role;

  GetNotificationsParams({required this.role});
}

class MarkNotificationAsReadUseCase {
  final NotificationRepository _repo = sl<NotificationRepository>();

  Future<void> call(String id) async {
    await _repo.markAsRead(id);
  }
}
class GetUnreadNotificationCountUseCase {
  final NotificationRepository _repo = sl<NotificationRepository>();

  Stream<int> call(String userId) {
    return _repo.unreadCount(userId);
  }
}
class GetNotificationUseCase1 {
  final NotificationRepository _repo = sl<NotificationRepository>();

  Future<Either> call({
    required String userId,
    required String role,
  }) async {
    return await _repo.getAllNotifications1(
      userId: userId,
      role: role,
    );
  }
}

