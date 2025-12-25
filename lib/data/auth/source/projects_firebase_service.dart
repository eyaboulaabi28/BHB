import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/presentation/pages/projects/final_commissioning_tests.dart';
import 'package:app_bhb/presentation/pages/projects/predefined_phases.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class ProjectsFirebaseService {
  Future<Either> addProject(Project project);
  Future<Either> getAllProjects();
  Future<Either> deleteProject(String id);
  Future<Either> getProjectById(String id);
  Future<void> updateSubStageStatus(
      String projectId,
      String stageId,
      String subId,
      String status,
      );
  Future<void> updateStageStatus(
      String projectId,
      String stageId,
      String status,
      );
  Future<void> updateTestStatus(
      String projectId,
      String sectionId,
      String testId,
      String status,
      );
  Future<void> updateTestSectionStatus(
      String projectId,
      String sectionId,
      String status,
      );
}

class ProjectsFirebaseServiceImpl extends ProjectsFirebaseService {

  final _projectsCollection = FirebaseFirestore.instance.collection('projects');
  Map<String, dynamic> buildInitialTestsStatus() {
    final Map<String, dynamic> result = {};

    for (final section in finalCommissioningTests) {
      result[section['section_id']] = {
        'status': 'en cours',
        'tests': {
          for (final test in section['tests'])
            test['id']: 'en cours'
        }
      };
    }

    return result;
  }
  Map<String, dynamic> buildInitialStagesStatus() {
    final Map<String, dynamic> result = {};

    for (final stage in predefinedPhasesStructure) {
      result[stage['id']] = {
        'status': 'en cours',
        'subStages': {
          for (final sub in stage['subPhases'])
            sub['id']: 'en cours'
        }
      };
    }

    return result;
  }
  @override
  Future<Either> addProject(Project project) async {
    try {
      await _projectsCollection.add({
        ...project.toMap(),
        'stagesStatus': buildInitialStagesStatus(),
        'testsStatus': buildInitialTestsStatus(),
      });
      return const Right('Project added successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }
  @override
  Future<Either> getAllProjects() async{
    try {
      final snapshot = await _projectsCollection.get();
      final project = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();
      return Right(project);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> deleteProject(String id) async {
    final tasksCollection = FirebaseFirestore.instance.collection('tasks');
    try {
      // 1️⃣ Supprimer toutes les tasks liées au project
      final querySnapshot = await tasksCollection
          .where('projectId', isEqualTo: id)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2️⃣ Supprimer le project lui-même
      final projectDoc = _projectsCollection.doc(id);
      batch.delete(projectDoc);

      // 3️⃣ Commit du batch
      await batch.commit();

      return const Right('Project and its tasks deleted successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }


  @override
  Future<Either> getProjectById(String id) async {
    try {
      final doc = await _projectsCollection.doc(id).get();
      if (!doc.exists) {
        return Left('Project not found');
      }
      final project = Project.fromMap(doc.id, doc.data()!);
      return Right(project);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> updateSubStageStatus(
      String projectId,
      String stageId,
      String subId,
      String status,
      ) async {
    await _projectsCollection.doc(projectId).update({
      'stagesStatus.$stageId.subStages.$subId': status,
    });
  }

  Future<void> updateStageStatus(
      String projectId,
      String stageId,
      String status,
      ) async {
    await _projectsCollection.doc(projectId).update({
      'stagesStatus.$stageId.status': status,
    });
  }
  Future<void> updateTestStatus(
      String projectId,
      String sectionId,
      String testId,
      String status,
      ) async {
    await _projectsCollection.doc(projectId).update({
      'testsStatus.$sectionId.tests.$testId': status,
    });
  }

  Future<void> updateTestSectionStatus(
      String projectId,
      String sectionId,
      String status,
      ) async {
    await _projectsCollection.doc(projectId).update({
      'testsStatus.$sectionId.status': status,
    });
  }

}