import 'package:app_bhb/data/auth/models/evaluation_engineer_model.dart';
import 'package:dartz/dartz.dart';


abstract class EvaluationEngineerRepository {
  Future<Either<String, EvaluationEngineer>> addEvaluationEngineer(EvaluationEngineer evaluation);
  Future<Either<String, List<EvaluationEngineer>>> getAllEvaluationEngineer();
  
}
