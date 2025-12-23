import 'package:app_bhb/data/auth/models/vacation_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class VacationFirebaseService {
  Future<Either<String, String>> addVacation(Vacation vacation);
  Future<Either<String, List<Vacation>>> getAllVacation();
  Future<Either<String, String>> deleteVacation(String id);
}

class VacationFirebaseServiceImpl extends VacationFirebaseService {
  final _firestore = FirebaseFirestore.instance;


  @override
  Future<Either<String, String>> addVacation(Vacation vacation) async{
    try {
      await _firestore.collection('vacation').add(vacation.toMap());
      return const Right('vacation added successfully');
    } catch (e) {
      return Left('Error adding vacation: $e');
    }
  }

  @override
  Future<Either<String, String>> deleteVacation(String id) async{
    try {
      await _firestore.collection('vacation').doc(id).delete();
      return const Right('vacation deleted successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<Vacation>>> getAllVacation() async {
    try {
      final querySnapshot = await _firestore.collection('vacation').get();
      final vacation = querySnapshot.docs
          .map((doc) => Vacation.fromMap(doc.id, doc.data()))
          .toList();
      return Right(vacation);
    } catch (e) {
      return Left('Error fetching vacation: $e');
    }
  }

}