import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/domain/auth/repository/daily_tasks_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddDailyTasksUseCase implements UseCase<Either<String,DailyTasks>, DailyTasks> {
  @override
  Future<Either<String, DailyTasks>> call({DailyTasks? params}) async {
    return await sl<DailyTasksRepository>().addDailyTask(params!);
  }
}
class GetAllDailyTasksUseCase implements UseCase<Either<String, List<DailyTasks>>, void> {
  @override
  Future<Either<String, List<DailyTasks>>> call({void params}) async {
    return await sl<DailyTasksRepository>().getAllDailyTasks();
  }
}
class UpdateDailyTasksStatusUseCase implements UseCase<Either, DailyTasks> {
  final DailyTasksRepository repository;

  UpdateDailyTasksStatusUseCase(this.repository);

  @override
  Future<Either> call({DailyTasks? params}) async {
    if (params == null) {
      return left("DailyTasks non fourni");
    }
    return await repository.updateDailyTaskStatus(params);
  }
}
class GetDailyTasksByStatusUseCase {
  final DailyTasksRepository repository;

  GetDailyTasksByStatusUseCase(this.repository);

  Future<Either<String, List<DailyTasks>>> call(String status) {
    return repository.getDailyTasksByStatus(status);
  }
}

class GetDailyTasksByEngineerIdStatusUseCase {
  final DailyTasksRepository repository;

  GetDailyTasksByEngineerIdStatusUseCase(this.repository);

  Future<Either<String, List<DailyTasks>>> call({
    required String engineerId,
    required String status,
  }) async {
    return await repository.getTasksByEngineerAndStatus(
      engineerId,
      status,
    );
  }
}

class CountTasksByEngineerPerMonthUseCase {
  final DailyTasksRepository repository;

  CountTasksByEngineerPerMonthUseCase(this.repository);

  Future<Either<String, int>> call({
    required String engineerId,
    required int year,
    required int month,
  }) {
    return repository.countTasksByEngineerPerMonth(engineerId, year, month);
  }
}

class CountCompletedTasksByEngineerPerMonthUseCase {
  final DailyTasksRepository repository;

  CountCompletedTasksByEngineerPerMonthUseCase(this.repository);

  Future<Either<String, int>> call({
    required String engineerId,
    required int year,
    required int month,
  }) {
    return repository.countCompletedTasksByEngineerPerMonth(engineerId, year, month);
  }
}
class GetTotalDurationByEngineerAndMonthUseCase implements UseCase<Either<String, int>, Map<String, dynamic>> {
  @override
  Future<Either<String, int>> call({Map<String, dynamic>? params}) async {
    final engineerId = params?['engineerId'];
    final year = params?['year'];
    final month = params?['month'];
    if (engineerId == null || year == null || month == null) return Left("Paramètres manquants");
    return await sl<DailyTasksRepository>().getTotalDurationByEngineerAndMonth(engineerId, year, month);
  }
}