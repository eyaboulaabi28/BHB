
import 'package:app_bhb/data/auth/models/attendance_time_model.dart';
import 'package:app_bhb/domain/auth/repository/attendance_time_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class UpdateAttendanceTimeUseCase implements UseCase<Either, Map<String, dynamic>> {

  @override
  Future<Either> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final attendanceTime = params['attendanceTime'] as AttendanceTime;
    return await sl<AttendanceTimeRepository>().updateAttendanceTime(id, attendanceTime);
  }
}
class GetAttendanceTimeUseCase implements UseCase<Either, void> {
  @override
  Future<Either> call({void params}) async {
    return await sl<AttendanceTimeRepository>().getAttendanceTime();
  }
}