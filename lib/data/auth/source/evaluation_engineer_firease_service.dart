import 'package:app_bhb/data/auth/models/evaluation_engineer_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class  EvaluationEngineerFirebaseService {
  Future<Either<String, String>> addEvaluationEngineer(EvaluationEngineer evaluation);
  Future<Either<String, List<EvaluationEngineer>>> getAllEvaluationEngineer();
}

class EvaluationEngineerFirebaseServiceImpl extends EvaluationEngineerFirebaseService {
  final _firestore = FirebaseFirestore.instance;


  @override
  Future<Either<String, String>> addEvaluationEngineer(EvaluationEngineer evaluation) async {
    try {
    /*  final query = await _firestore
          .collection('evaluationEngineer')
          .where('idProject', isEqualTo: evaluation.idProject)
          .where('stepId', isEqualTo: evaluation.stepId)
          .get();

      if (query.docs.isNotEmpty) {
        return Left('Evaluation already exists for this project');
      }*/
      await _firestore
          .collection('evaluationEngineer')
          .add(evaluation.toMap());

      return const Right('Evaluation added successfully');

    } catch (e) {
      return Left('Error adding evaluation: $e');
    }
  }
  @override
  Future<Either<String, List<EvaluationEngineer>>> getAllEvaluationEngineer()async{
    try {
      final querySnapshot = await _firestore.collection('evaluationEngineer').get();
      final vacation = querySnapshot.docs
          .map((doc) => EvaluationEngineer.fromMap(doc.id, doc.data()))
          .toList();
      return Right(vacation);
    } catch (e) {
      return Left('Error fetching vacation: $e');
    };
  }
@override
  Future<void> updateEvaluation({
    required String projectId,
    required String engineerId,
    required String stepKey,
    required int score,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('evaluationEngineer')
        .doc("$projectId-$engineerId");

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        transaction.set(ref, {
          "idProject": projectId,
          "idEngineer": engineerId,
          "totalScore": 0,
          "steps": {},
        });
      }

      final data = snapshot.data() ?? {};
      final steps = Map<String, dynamic>.from(data['steps'] ?? {});

      steps[stepKey] = {
        "score": score,
        "status": "done",
      };

      int total = 0;
      steps.forEach((k, v) {
        total += (v['score'] ?? 0) as int;
      });

      transaction.update(ref, {
        "steps": steps,
        "totalScore": total,
      });
    });
  }

}