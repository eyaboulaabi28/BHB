import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:dartz/dartz.dart';

abstract class ProjectsRepository {
  Future<Either> addProject(Project project);
  Future<Either> getAllProjects();
  Future<Either> deleteProject(String id);
  Future<Either> getProjectById(String id);
  Future<void> updateStageStatus(
      String projectId,
      String stageId,
      String status,
      );
  Future<void> updateSubStageStatus(
      String projectId,
      String stageId,
      String subId,
      String status,
      );

  Future<void> updateTestSectionStatus(
      String projectId,
      String sectionId,
      String status,
      );
  Future<void> updateTestStatus(
      String projectId,
      String sectionId,
      String testId,
      String status,
      );
}
