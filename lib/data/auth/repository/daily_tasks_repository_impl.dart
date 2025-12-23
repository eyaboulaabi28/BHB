import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/data/auth/source/daily_task_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/daily_tasks_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class DailyTasksRepositoryImpl extends DailyTasksRepository {

  @override
  Future<Either<String, DailyTasks>> addDailyTask(DailyTasks dailyTasks) async{
    final result = await sl<DailyTasksFirebaseService>().addDailyTask(dailyTasks);
    return result.fold(
          (l) => Left(l),
          (r) => Right(dailyTasks),
    );
  }

  @override
  Future<Either<String, List<DailyTasks>>> getAllDailyTasks() async{
    return await sl<DailyTasksFirebaseService>().getAllDailyTasks();
  }

  @override
  Future<Either<String, Unit>> updateDailyTaskStatus(DailyTasks dailyTasks) async{
    return await sl<DailyTasksFirebaseService>().updateDailyTaskStatus(dailyTasks);
  }


  @override
  Future<Either<String, List<DailyTasks>>> getDailyTasksByStatus(String status) async {
    return await sl<DailyTasksFirebaseService>().getDailyTasksByStatus(status);
  }

  @override
  Future<Either<String, List<DailyTasks>>> getTasksByEngineerAndStatus(String engineerId, String status) async {
    return await sl<DailyTasksFirebaseService>().getTasksByEngineerAndStatus(engineerId, status);

  }
  

  @override
  Future<Either<String, int>> countTasksByEngineerPerMonth(
      String engineerId, int year, int month) async {
    return await sl<DailyTasksFirebaseService>().countTasksByEngineerPerMonth(engineerId, year, month);
  }

  @override
  Future<Either<String, int>> countCompletedTasksByEngineerPerMonth(
      String engineerId, int year, int month) async {
    return await sl<DailyTasksFirebaseService>().countCompletedTasksByEngineerPerMonth(engineerId, year, month);
  }

  @override
  Future<Either<String, int>> getTotalDurationByEngineerAndMonth(String engineerId, int year, int month) async {
    return await sl<DailyTasksFirebaseService>().getTotalDurationByEngineerAndMonth(engineerId, year, month);

  }



}