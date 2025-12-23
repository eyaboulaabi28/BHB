import 'package:app_bhb/data/auth/models/check_in.dart';
import 'package:app_bhb/domain/auth/repository/check_in_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddDailyCheckInUseCase implements UseCase<Either<String,DailyCheckIn>, DailyCheckIn> {
  @override
  Future<Either<String, DailyCheckIn>> call({DailyCheckIn? params}) async {
    return await sl<CheckInRepository>().addCheckIn(params!);
  }
}

class GetAllDailyCheckInUseCase implements UseCase<Either<String, List<DailyCheckIn>>, void> {
  @override
  Future<Either<String, List<DailyCheckIn>>> call({void params}) async {
    return await sl<CheckInRepository>().getAllDailyCheckIn();
  }
}

class UpdateDailyCheckInUseCase implements UseCase<Either<String, DailyCheckIn>, DailyCheckIn> {
  @override
  Future<Either<String, DailyCheckIn>> call({DailyCheckIn? params}) async {
    if (params == null) return Left("Paramètre check-in manquant");
    return await sl<CheckInRepository>().updateCheckIn(params);
  }
}
class GetTotalHoursByEngineerAndMonthUseCase implements UseCase<Either<String, double>, Map<String, dynamic>> {
  @override
  Future<Either<String, double>> call({Map<String, dynamic>? params}) async {
    final engineerId = params?['engineerId'];
    final year = params?['year'];
    final month = params?['month'];
    if (engineerId == null || year == null || month == null) return Left("Paramètres manquants");
    return await sl<CheckInRepository>().getTotalHoursByEngineerAndMonth(engineerId, year, month);
  }
}

class GetOvertimeHoursByEngineerAndMonthUseCase implements UseCase<Either<String, double>, Map<String, dynamic>> {
  @override
  Future<Either<String, double>> call({Map<String, dynamic>? params}) async {
    final engineerId = params?['engineerId'];
    final year = params?['year'];
    final month = params?['month'];
    if (engineerId == null || year == null || month == null) return Left("Paramètres manquants");
    return await sl<CheckInRepository>().getOvertimeHoursByEngineerAndMonth(engineerId, year, month);
  }
}

class GetTotalDaysByEngineerAndMonthUseCase implements UseCase<Either<String, int>, Map<String, dynamic>> {
  @override
  Future<Either<String, int>> call({Map<String, dynamic>? params}) async {
    final engineerId = params?['engineerId'];
    final year = params?['year'];
    final month = params?['month'];
    if (engineerId == null || year == null || month == null) return Left("Paramètres manquants");
    return await sl<CheckInRepository>().getTotalDaysByEngineerAndMonth(engineerId, year, month);
  }
}
