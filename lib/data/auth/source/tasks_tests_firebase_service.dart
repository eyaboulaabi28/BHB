import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class TasksTestsFirebaseService {
  Future<Either<String, Unit>> addTaskTest(TasksTests taskTest);
  Future<Either> getAllTaskTest();
  Future<Either<String, List<TasksTests>>> getTasksBySubTest(String subStageId,String projectId);

}
class TasksTestsFirebaseServiceImpl extends TasksTestsFirebaseService {

  final _tasksTestsCollection = FirebaseFirestore.instance.collection('tasksTest');

  @override
  Future<Either<String, Unit>> addTaskTest(TasksTests taskTest) async {
    try {
      if (taskTest.subTestId== null || taskTest.subTestId!.isEmpty) {
        return left("L'ID du Sub test  est requis pour ajouter un test.");
      }
      final taskTestData = taskTest.toMap();
      await _tasksTestsCollection.add(taskTestData);
      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }

  @override
  Future<Either> getAllTaskTest() async{
    try {
      final snapshot = await _tasksTestsCollection.get();
      final taskTest = snapshot.docs
          .map((doc) => TasksTests.fromMap(doc.id, doc.data()))
          .toList();
      return Right(taskTest);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<TasksTests>>> getTasksBySubTest(String subStageId,String projectId)async {
    try {
      final snapshot = await _tasksTestsCollection
          .where('subTestId', isEqualTo: subStageId)
          .where('projectId', isEqualTo: subStageId)
          .get();

      final taskTest = snapshot.docs
          .map((doc) => TasksTests.fromMap(doc.id, doc.data()))
          .toList();

      return Right(taskTest);
    } catch (e) {
      return Left(e.toString());
    }
  }
}


