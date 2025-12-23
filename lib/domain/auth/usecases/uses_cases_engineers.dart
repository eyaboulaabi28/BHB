import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/domain/auth/repository/engineers_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';



class AddEngineerUseCase implements UseCase<Either, Engineer> {
  @override
  Future<Either> call({Engineer? params}) async {
    return await sl<EngineerRepository>().addEngineer(params!);
  }
}

class GetEngineersUseCase implements UseCase<Either, void> {
  @override
  Future<Either> call({void params}) async {
    return await sl<EngineerRepository>().getAllEngineers();
  }
}

class UpdateEngineerUseCase implements UseCase<Either, Map<String, dynamic>> {
  @override
  Future<Either> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final engineer = params['engineer'] as Engineer;
    return await sl<EngineerRepository>().updateEngineer(id, engineer);
  }
}

class DeleteEngineerUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call({String? params}) async {
    return await sl<EngineerRepository>().deleteEngineer(params!);
  }

}

class CheckEmailUsedUseCase {
  final EngineerRepository repository;

  CheckEmailUsedUseCase(this.repository);

  Future<bool> call(String email) async {
    return await repository.isEmailUsed(email);
  }
}

