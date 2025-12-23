
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class NotificationFirebaseService {
  Future<void> createNotification(NotificationsModel notification);
  Future<Either> getAllNotifications();
  Future<void> markAsRead(String id);

}
class NotificationFirebaseServiceImpl implements NotificationFirebaseService {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createNotification(NotificationsModel notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }

  @override
  Future<Either> getAllNotifications() async {
    try {
      // On trie par "createdAt" décroissant pour avoir les plus récentes en premier
      final querySnapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationsModel.fromMap(doc.id, doc.data()))
          .toList();

      return Right(notifications);
    } catch (e) {
      return Left('Error fetching notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }
}