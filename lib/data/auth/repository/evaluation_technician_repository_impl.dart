import 'package:app_bhb/data/auth/models/evaluation_technician_model.dart';
import 'package:app_bhb/data/auth/source/evaluation_technician_firease_service.dart';
import 'package:dartz/dartz.dart';
import '../../../domain/auth/repository/evaluation_technician_repository.dart';
import '../../../service_locator.dart';

class EvaluationTechnicianRepositoryImpl extends EvaluationTechnicianRepository {




  @override
  Future<Either<String, EvaluationTechnician>> addEvaluationTechnician(EvaluationTechnician evaluation) async{
    final result = await sl<EvaluationTechnicianFirebaseService>().addEvaluationTechnician(evaluation);
    return result.fold(
          (l) => Left(l),
          (r) => Right(evaluation),
    );
  }

  @override
  Future<Either<String, List<EvaluationTechnician>>> getAllEvaluationTechnician() async{
    return await sl<EvaluationTechnicianFirebaseService>().getAllEvaluationTechnician();
  }

}