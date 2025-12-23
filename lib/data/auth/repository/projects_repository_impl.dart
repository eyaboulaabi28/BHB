import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/source/projects_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/projects_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class ProjectsRepositoryImpl extends ProjectsRepository {


  @override
  Future<Either> addProject(Project project) async {
    return await sl<ProjectsFirebaseService>().addProject(project);

  }

  @override
  Future<Either> getAllProjects() async{
    return await sl<ProjectsFirebaseService>().getAllProjects();

  }

  @override
  Future<Either> deleteProject(String id) async {
    return await sl<ProjectsFirebaseService>().deleteProject(id);

  }

  @override
  Future<Either> getProjectById(String id) async {
    return await sl<ProjectsFirebaseService>().getProjectById(id);
  }

  @override
  Future<void> updateStageStatus(String projectId, String stageId, String status) async {
    return await sl<ProjectsFirebaseService>().updateStageStatus(projectId, stageId, status);
  }

  @override
  Future<void> updateSubStageStatus(String projectId, String stageId, String subId, String status)async {
    return await sl<ProjectsFirebaseService>().updateSubStageStatus(projectId, stageId, subId, status);
  }

  @override
  Future<void> updateTestSectionStatus(String projectId, String sectionId, String status)async {
    return await sl<ProjectsFirebaseService>().updateTestSectionStatus(projectId, sectionId, status);

  }

  @override
  Future<void> updateTestStatus(String projectId, String sectionId, String testId, String status) async{
    return await sl<ProjectsFirebaseService>().updateTestStatus(projectId, sectionId, testId, status);

  }
}