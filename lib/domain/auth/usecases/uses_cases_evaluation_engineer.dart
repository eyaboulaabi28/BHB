import 'package:app_bhb/data/auth/models/evaluation_engineer_model.dart';
import 'package:app_bhb/domain/auth/repository/evaluation_engineer_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddEvaluationEngineerUseCase implements UseCase<Either<String, EvaluationEngineer>, EvaluationEngineer> {
  @override
  Future<Either<String, EvaluationEngineer>> call({EvaluationEngineer? params}) async {
    return await sl<EvaluationEngineerRepository>().addEvaluationEngineer(params!);
  }
}
class GetAllEvaluationEngineerUseCase implements UseCase<Either<String, List<EvaluationEngineer>>, void> {
  @override
  Future<Either<String, List<EvaluationEngineer>>> call({void params}) async {
    return await sl<EvaluationEngineerRepository>().getAllEvaluationEngineer();
  }
}