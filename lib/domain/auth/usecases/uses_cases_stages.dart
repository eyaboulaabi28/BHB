import 'package:app_bhb/data/auth/models/stages_model.dart';
import 'package:app_bhb/domain/auth/repository/stages_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';

class AddStageUseCase implements UseCase<Either<String, String>, Stage> {
  final StagesRepository repository;

  AddStageUseCase(this.repository);

  @override
  Future<Either<String, String>> call({Stage? params}) async {
    return await repository.addStage(params!);
  }
}

class GetStageUseCase implements UseCase<Either, void> {
  final StagesRepository _repo;

  GetStageUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllStages();
  }
}
class UpdateStageStatusUseCase implements UseCase<Either, Stage> {
  final StagesRepository repository;

  UpdateStageStatusUseCase(this.repository);

  @override
  Future<Either> call({Stage? params}) async {
    if (params == null) {
      return left("SubStage non fourni");
    }
    return await repository.updateStageStatus(params);
  }
}
