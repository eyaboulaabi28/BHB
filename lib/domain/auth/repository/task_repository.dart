import 'package:dartz/dartz.dart';
import 'package:app_bhb/data/auth/models/tasks_model.dart';

abstract class TasksRepository {
  Future<Either<String, Unit>> addTask(Tasks task);
  Future<Either> getAllTask();
  Future<Either<String, List<Tasks>>> getTasksBySubStage(String subStageId,String projectId);
  Future<Either<String, Unit>> deleteTask(String taskId);
  Future<Either<String, Unit>> updateTask(Tasks task);
}