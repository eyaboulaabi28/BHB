import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:app_bhb/data/auth/source/tasks_tests_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/tasks_test_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class TasksTestRepositoryImpl extends TasksTestRepository {

  @override
  Future<Either<String, Unit>> addTaskTest(TasksTests taskTest) async{
    return await sl<TasksTestsFirebaseService>().addTaskTest(taskTest);
  }

  @override
  Future<Either> getAllTaskTest() async{
    return await sl<TasksTestsFirebaseService>().getAllTaskTest();

  }

  @override
  Future<Either<String, List<TasksTests>>> getTasksBySubTest(String subStageId,String projectId) async{
    return await sl<TasksTestsFirebaseService>().getTasksBySubTest(subStageId,projectId);

  }

}