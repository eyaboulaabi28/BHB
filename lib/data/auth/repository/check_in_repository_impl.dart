import 'package:app_bhb/data/auth/models/check_in.dart';
import 'package:app_bhb/data/auth/source/check_in_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/check_in_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class CheckInRepositoryImpl extends CheckInRepository {
  final CheckInFirebaseService _service = sl<CheckInFirebaseService>();

  @override
  Future<Either<String, DailyCheckIn>> addCheckIn(DailyCheckIn checkIn) async {
    final result = await _service.addCheckIn(checkIn);
    return result.fold(
          (l) => Left(l),
          (r) => Right(checkIn),
    );
  }

  @override
  Future<Either<String, List<DailyCheckIn>>> getAllDailyCheckIn() async {
    return await _service.getAllDailyCheckIn();
  }

  @override
  Future<Either<String, DailyCheckIn>> updateCheckIn(DailyCheckIn checkIn) async {
    final result = await _service.updateCheckIn(checkIn);
    return result.fold(
          (l) => Left(l),
          (r) => Right(checkIn),
    );
  }

  // -------------------- NOUVELLES FONCTIONS -------------------- //

  @override
  Future<Either<String, double>> getTotalHoursByEngineerAndMonth(String engineerId, int year, int month) {
    return _service.getTotalHoursByEngineerAndMonth(engineerId, year, month);
  }

  @override
  Future<Either<String, double>> getOvertimeHoursByEngineerAndMonth(String engineerId, int year, int month) {
    return _service.getOvertimeHoursByEngineerAndMonth(engineerId, year, month);
  }

  @override
  Future<Either<String, int>> getTotalDaysByEngineerAndMonth(String engineerId, int year, int month) {
    return _service.getTotalDaysByEngineerAndMonth(engineerId, year, month);
  }
}