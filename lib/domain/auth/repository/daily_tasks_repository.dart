import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:dartz/dartz.dart';

abstract class DailyTasksRepository {
  Future<Either<String, DailyTasks>> addDailyTask(DailyTasks dailyTasks);
  Future<Either<String, List<DailyTasks>>> getAllDailyTasks();
  Future<Either<String, Unit>> updateDailyTaskStatus(DailyTasks dailyTasks);
  Future<Either<String, List<DailyTasks>>> getDailyTasksByStatus(String status);
  Future<Either<String, List<DailyTasks>>> getTasksByEngineerAndStatus(String engineerId, String status);
  Future<Either<String, int>> countTasksByEngineerPerMonth(String engineerId, int year, int month);
  Future<Either<String, int>> countCompletedTasksByEngineerPerMonth(String engineerId, int year, int month);
  Future<Either<String, int>> getTotalDurationByEngineerAndMonth(
      String engineerId, int year, int month);
}
