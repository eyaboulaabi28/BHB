
import 'package:app_bhb/data/auth/models/check_in.dart';
import 'package:dartz/dartz.dart';

abstract class CheckInRepository {
  Future<Either<String, DailyCheckIn>> addCheckIn(DailyCheckIn checkIn);
  Future<Either<String, List<DailyCheckIn>>> getAllDailyCheckIn();
  Future<Either<String, DailyCheckIn>> updateCheckIn(DailyCheckIn checkIn);
  Future<Either<String, double>> getTotalHoursByEngineerAndMonth(String engineerId, int year, int month);
  Future<Either<String, double>> getOvertimeHoursByEngineerAndMonth(String engineerId, int year, int month);
  Future<Either<String, int>> getTotalDaysByEngineerAndMonth(String engineerId, int year, int month);
}


