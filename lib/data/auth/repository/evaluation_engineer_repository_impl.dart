import 'package:app_bhb/data/auth/models/evaluation_engineer_model.dart';
import 'package:app_bhb/data/auth/source/evaluation_engineer_firease_service.dart';
import 'package:app_bhb/domain/auth/repository/evaluation_engineer_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class EvaluationEngineerRepositoryImpl extends EvaluationEngineerRepository {


  @override
  Future<Either<String, EvaluationEngineer>> addEvaluationEngineer(EvaluationEngineer evaluation) async {
    final result = await sl<EvaluationEngineerFirebaseService>().addEvaluationEngineer(evaluation);
    return result.fold(
          (l) => Left(l),
          (r) => Right(evaluation),
    );
  }

  @override
  Future<Either<String, List<EvaluationEngineer>>> getAllEvaluationEngineer() async {
    return await sl<EvaluationEngineerFirebaseService>().getAllEvaluationEngineer();

  }

}