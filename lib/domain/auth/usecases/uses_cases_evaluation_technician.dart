import 'package:app_bhb/data/auth/models/evaluation_technician_model.dart';
import 'package:app_bhb/domain/auth/repository/evaluation_technician_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddEvaluationTechnicianUseCase implements UseCase<Either<String, EvaluationTechnician>, EvaluationTechnician> {
  @override
  Future<Either<String, EvaluationTechnician>> call({EvaluationTechnician? params}) async {
    return await sl<EvaluationTechnicianRepository>().addEvaluationTechnician(params!);
  }
}
class GetAllEvaluationTechnicianUseCase implements UseCase<Either<String, List<EvaluationTechnician>>, void> {
  @override
  Future<Either<String, List<EvaluationTechnician>>> call({void params}) async {
    return await sl<EvaluationTechnicianRepository>().getAllEvaluationTechnician();
  }
}