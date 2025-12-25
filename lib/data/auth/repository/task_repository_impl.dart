import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:app_bhb/data/auth/source/tasks_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/task_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class TasksRepositoryImpl extends TasksRepository {

  @override
  Future<Either<String, Unit>> addTask(Tasks task) async {
    return await sl<TasksFirebaseService>().addTask(task);
  }
  @override
  Future<Either> getAllTask() async{
    return await sl<TasksFirebaseService>().getAllTask();
  }
  @override
  Future<Either<String, List<Tasks>>> getTasksBySubStage(String subStageId,String projectId) async {
    return await sl<TasksFirebaseService>()
        .getTasksBySubStage(subStageId,projectId);
  }

  @override
  Future<Either<String, Unit>> deleteTask(String taskId) async{
    return await sl<TasksFirebaseService>().deleteTask(taskId);
  }

  @override
  Future<Either<String, Unit>> updateTask(Tasks task) async {
    return await sl<TasksFirebaseService>().updateTask(task);
  }

}