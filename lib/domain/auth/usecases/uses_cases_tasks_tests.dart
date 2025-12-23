import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:app_bhb/domain/auth/repository/tasks_test_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';

class AddTasksTestUseCase implements UseCase<Either, TasksTests> {
  final TasksTestRepository repository;

  AddTasksTestUseCase(this.repository);

  @override
  Future<Either> call({TasksTests? params}) async {
    return await repository.addTaskTest(params!);
  }
}
class GetTaskTestUseCase implements UseCase<Either, void> {
  final TasksTestRepository _repo;

  GetTaskTestUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllTaskTest();
  }
}

class GetTasksTestsBySubStageUseCase implements UseCase<Either<String, List<TasksTests>>, GetTasksTestBySubStageParams> {
  final TasksTestRepository repo;

  GetTasksTestsBySubStageUseCase(this.repo);

  @override
  Future<Either<String, List<TasksTests>>> call({GetTasksTestBySubStageParams? params,}) async {
    return await repo.getTasksBySubTest(
      params!.subStageId,
      params.projectId,
    );
  }
}
class GetTasksTestBySubStageParams {
  final String subStageId;
  final String projectId;

  GetTasksTestBySubStageParams({
    required this.subStageId,
    required this.projectId,
  });
}