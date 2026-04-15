import 'package:app_bhb/data/auth/models/evaluation_technician_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class  EvaluationTechnicianFirebaseService {
  Future<Either<String, String>> addEvaluationTechnician(EvaluationTechnician evaluation);
  Future<Either<String, List<EvaluationTechnician>>> getAllEvaluationTechnician();
}

class EvaluationTechnicianFirebaseServiceImpl extends EvaluationTechnicianFirebaseService {
  final _firestore = FirebaseFirestore.instance;



  @override
  Future<Either<String, List<EvaluationTechnician>>> getAllEvaluationTechnician() async{
    try {
      final querySnapshot = await _firestore.collection('evaluationTechnician').get();
      final evaluation = querySnapshot.docs
          .map((doc) => EvaluationTechnician.fromMap(doc.id, doc.data()))
          .toList();
      return Right(evaluation);
    } catch (e) {
      return Left('Error fetching evaluation: $e');
    };
  }

  @override
  Future<Either<String, String>> addEvaluationTechnician(EvaluationTechnician evaluation) async{
    try {

      await _firestore
          .collection('evaluationTechnician')
          .add(evaluation.toMap());

      return const Right('Evaluation added successfully');

    } catch (e) {
      return Left('Error adding evaluation: $e');
    }
  }

}