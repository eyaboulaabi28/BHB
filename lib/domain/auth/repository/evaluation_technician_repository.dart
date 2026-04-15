import 'package:app_bhb/data/auth/models/evaluation_technician_model.dart';
import 'package:dartz/dartz.dart';


abstract class EvaluationTechnicianRepository {
  Future<Either<String, EvaluationTechnician>> addEvaluationTechnician(EvaluationTechnician evaluation);
  Future<Either<String, List<EvaluationTechnician>>> getAllEvaluationTechnician();
}
