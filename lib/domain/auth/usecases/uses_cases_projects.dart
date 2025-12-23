import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/repository/projects_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';



class AddProjectUseCase implements UseCase<Either, Project> {

  @override
  Future<Either> call({Project? params}) async {
    return await sl<ProjectsRepository>().addProject(params!);
  }
}
class GetProjectUseCase implements UseCase<Either, void> {
  final ProjectsRepository _repo;

  GetProjectUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllProjects();
  }
}
class DeleteProjectUseCase implements UseCase<Either, String> {
  final ProjectsRepository _repository;

  DeleteProjectUseCase(this._repository);

  @override
  Future<Either> call({String? params}) async {
    return await _repository.deleteProject(params!);
  }
}

class GetProjectByIdUseCase implements UseCase<Either, String> {
  final ProjectsRepository _repository;

  GetProjectByIdUseCase(this._repository);

  @override
  Future<Either> call({String? params}) async {
    return await _repository.getProjectById(params!);
  }
}

class UpdateSubStageStatusUseCase
    implements UseCase<void, UpdateSubStageStatusParams> {

  final ProjectsRepository _repository;

  UpdateSubStageStatusUseCase(this._repository);

  @override
  Future<void> call({UpdateSubStageStatusParams? params}) async {
    await _repository.updateSubStageStatus(
      params!.projectId,
      params.stageId,
      params.subId,
      params.status,
    );
  }
}
class UpdateStageStatusUseCase
    implements UseCase<void, UpdateStageStatusParams> {

  final ProjectsRepository _repository;

  UpdateStageStatusUseCase(this._repository);

  @override
  Future<void> call({UpdateStageStatusParams? params}) async {
    await _repository.updateStageStatus(
      params!.projectId,
      params.stageId,
      params.status,
    );
  }
}
class UpdateStageStatusParams {
  final String projectId;
  final String stageId;
  final String status;

  UpdateStageStatusParams({
    required this.projectId,
    required this.stageId,
    required this.status,
  });
}
class UpdateSubStageStatusParams {
  final String projectId;
  final String stageId;
  final String subId;
  final String status;

  UpdateSubStageStatusParams({
    required this.projectId,
    required this.stageId,
    required this.subId,
    required this.status,
  });
}
class UpdateTestSectionStatusUseCase
    implements UseCase<void, UpdateTestSectionStatusParams> {

  final ProjectsRepository _repository;

  UpdateTestSectionStatusUseCase(this._repository);

  @override
  Future<void> call({UpdateTestSectionStatusParams? params}) async {
    await _repository.updateTestSectionStatus(
      params!.projectId,
      params.sectionId,
      params.status,
    );
  }
}
class UpdateTestSectionStatusParams {
  final String projectId;
  final String sectionId;
  final String status;

  UpdateTestSectionStatusParams({
    required this.projectId,
    required this.sectionId,
    required this.status,
  });
}

class UpdateTestStatusParams {
  final String projectId;
  final String sectionId;
  final String testId;
  final String status;

  UpdateTestStatusParams({
    required this.projectId,
    required this.sectionId,
    required this.testId,
    required this.status,
  });
}
class UpdateTestStatusUseCase
    implements UseCase<void, UpdateTestStatusParams> {

  final ProjectsRepository _repository;

  UpdateTestStatusUseCase(this._repository);

  @override
  Future<void> call({UpdateTestStatusParams? params}) async {
    await _repository.updateTestStatus(
      params!.projectId,
      params.sectionId,
      params.testId,
      params.status,
    );
  }
}
