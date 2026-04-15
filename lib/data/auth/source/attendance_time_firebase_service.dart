
import 'package:app_bhb/data/auth/models/attendance_time_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


abstract class AttendanceTimeFirebaseService {

  Future<Either> updateAttendanceTime(String id, AttendanceTime attendanceTime);
  Future<Either> getAttendanceTime();

}
class AttendanceTimeFirebaseServiceImpl extends AttendanceTimeFirebaseService {

  final _firestore = FirebaseFirestore.instance;

  @override
  Future<Either> updateAttendanceTime(String id, AttendanceTime attendanceTime) async{
    try {
      await _firestore.collection('AttendanceTime').doc(id).update(attendanceTime.toMap());
      return const Right('attendanceTime updated successfully');
    } catch (e) {
      return Left('Error updating attendanceTime: $e');
    }
  }

  @override
  Future<Either> getAttendanceTime() async {
    try {
      final snapshot = await _firestore
          .collection('AttendanceTime')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = snapshot.docs.first;

      final attendance = AttendanceTime.fromMap(doc.id, doc.data());

      return Right(attendance);
    } catch (e) {
      return Left("Error fetching attendance time: $e");
    }
  }

}




