import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class TasksFirebaseService {
  Future<Either<String, Unit>> addTask(Tasks task);
  Future<Either> getAllTask();
  Future<Either<String, List<Tasks>>> getTasksBySubStage(String subStageId,String projectId);


}
class TasksFirebaseServiceImpl extends TasksFirebaseService {

  final _tasksCollection = FirebaseFirestore.instance.collection('tasks');

  @override
  Future<Either<String, Unit>> addTask(Tasks task) async {
    try {
      if (task.subStageId== null || task.subStageId!.isEmpty) {
        return left("L'ID du Sub Stage  est requis pour ajouter une étape.");
      }
      final taskData = task.toMap();
      await _tasksCollection.add(taskData);
      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }

  @override
  Future<Either<String, List<Tasks>>> getTasksBySubStage(String subStageId,String projectId) async {
    try {
      final snapshot = await _tasksCollection
          .where('subStageId', isEqualTo: subStageId)
          .where('projectId', isEqualTo: projectId)
          .get();

      final tasks = snapshot.docs
          .map((doc) => Tasks.fromMap(doc.id, doc.data()))
          .toList();

      return Right(tasks);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> getAllTask() async {
    try {
      final snapshot = await _tasksCollection.get();
      final test = snapshot.docs
          .map((doc) => Tasks.fromMap(doc.id, doc.data()))
          .toList();
      return Right(test);
    } catch (e) {
      return Left(e.toString());
    }
  }
}

