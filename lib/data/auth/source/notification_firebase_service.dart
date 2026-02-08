
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class NotificationFirebaseService {
  Future<void> createNotification(NotificationsModel notification);
  Future<void> markAsRead(String id);
  Stream<int> unreadNotificationsCount(String userId);
  Future<Either> getAllNotifications1({
    required String userId,
    required String role,
  });
  Future<Either> getAllNotifications({
    required String role,
  });
}
class NotificationFirebaseServiceImpl implements NotificationFirebaseService {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createNotification(NotificationsModel notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }

  @override
  Future<Either> getAllNotifications({
    required String role,
  }) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;

      Query query = _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true);

      if (role == "admin" || role=="engineer") {
        // 👑 admin يشوف الكل
      } else {
        query = query.where(
          Filter.or(
            // notification spécifique à l'utilisateur
            Filter('userId', isEqualTo: currentUid),

            // notification liée à un projet
            Filter('targetRole', isEqualTo: "project"),
          ),
        );
      }

      final snapshot = await query.get();

      final notifications = snapshot.docs
          .map((doc) => NotificationsModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      ))
          .toList();

      return Right(notifications);
    } catch (e) {
      return Left(e.toString());
    }
  }




  @override
  Future<void> markAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }
  @override
  Stream<int> unreadNotificationsCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<Either> getAllNotifications1({required String userId, required String role,}) async {
    try {
      Query query = _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true);

      // 👇 customer يشوف غير متاعو
      if (role == "customer") {
        query = query.where('userId', isEqualTo: userId);
      }

      final querySnapshot = await query.get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationsModel.fromMap(doc.id, doc.data() as Map<String, dynamic>,))
          .toList();

      return Right(notifications);
    } catch (e) {
      print('Error fetching notifications: $e');
      return Left('Error fetching notifications: $e');
    }
  }


}