import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


abstract class EngineerFirebaseService {
  Future<Either> addEngineer(Engineer engineer);
  Future<Either> getAllEngineers();
  Future<Either> updateEngineer(String id, Engineer engineer);
  Future<Either> deleteEngineer(String id);
  Future<bool> isEmailUsed(String email);
}
class EngineerFirebaseServiceImpl extends EngineerFirebaseService {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<Either> addEngineer(Engineer engineer) async {
    try {
      final doc = await _firestore.collection('Users').add(engineer.toMap());
      return Right(doc.id);
    } catch (e) {
      return Left('Error adding engineer: $e');
    }
  }

  @override
  Future<Either> getAllEngineers() async {
    try {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'engineer')
          .get();

      final engineers = querySnapshot.docs
          .map((doc) {
        print("Fetched engineer id: ${doc.id}");
        return Engineer.fromMap(doc.id, doc.data());
      }).toList();

      return Right(engineers);
    } catch (e) {
      return Left('Error fetching engineers: $e');
    }
  }

  @override
  Future<Either> updateEngineer(String id, Engineer engineer) async {
    try {
      await _firestore.collection('Users').doc(id).update(engineer.toMap());
      return const Right('Engineer updated successfully');
    } catch (e) {
      return Left('Error updating engineer: $e');
    }
  }

  @override
  Future<Either> deleteEngineer(String id) async {
    try {
      await _firestore.collection('Users').doc(id).delete();
      return const Right('Engineer deleted successfully');
    } catch (e) {
      return Left('Error deleting engineer: $e');
    }
  }

  @override
  Future<bool> isEmailUsed(String email) async {
    final querySnapshot = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
