import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/domain/auth/repository/sub_stages_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';

class AddSubStageUseCase implements UseCase<Either, SubStage> {
  final SubStagesRepository repository;

  AddSubStageUseCase(this.repository);

  @override
  Future<Either> call({SubStage? params}) async {
    return await repository.addSubStage(params!);
  }
}
class GetSubStageUseCase implements UseCase<Either, void> {
  final SubStagesRepository _repo;

  GetSubStageUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllSubStages();
  }
}
class UpdateSubStageStatusUseCase implements UseCase<Either, SubStage> {
  final SubStagesRepository repository;

  UpdateSubStageStatusUseCase(this.repository);

  @override
  Future<Either> call({SubStage? params}) async {
    if (params == null) {
      return left("SubStage non fourni");
    }
    return await repository.updateSubStageStatus(params);
  }
}
