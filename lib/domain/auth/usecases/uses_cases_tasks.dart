import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:app_bhb/domain/auth/repository/task_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';

class AddTasksUseCase implements UseCase<Either, Tasks> {
  final TasksRepository repository;

  AddTasksUseCase(this.repository);

  @override
  Future<Either> call({Tasks? params}) async {
    return await repository.addTask(params!);
  }
}
class GetTaskUseCase implements UseCase<Either, void> {
  final TasksRepository _repo;

  GetTaskUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllTask();
  }
}
class GetTasksBySubStageUseCase implements UseCase<Either<String, List<Tasks>>, GetTasksBySubStageParams> {
  final TasksRepository repo;

  GetTasksBySubStageUseCase(this.repo);

  @override
  Future<Either<String, List<Tasks>>> call({GetTasksBySubStageParams? params,}) async {
    return await repo.getTasksBySubStage(
      params!.subStageId,
      params.projectId,
    );
  }
}
class GetTasksBySubStageParams {
  final String subStageId;
  final String projectId;

  GetTasksBySubStageParams({
    required this.subStageId,
    required this.projectId,
  });
}
