import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:dartz/dartz.dart';

abstract class TasksTestRepository {
  Future<Either<String, Unit>> addTaskTest(TasksTests taskTest);
  Future<Either> getAllTaskTest();
  Future<Either<String, List<TasksTests>>> getTasksBySubTest(String subStageId,String projectId);

}