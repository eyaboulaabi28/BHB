import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/source/attendance_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/attendance_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class AttendanceRepositoryImpl extends AttendanceRepository {

  @override
  Future<Either> addAttendance(Attendance attendance) async{
    return await sl<AttendanceFirebaseService>().addAttendance(attendance);

  }

  @override
  Future<Either> getAllAttendance() async{
    return await sl<AttendanceFirebaseService>().getAllAttendance();
  }

  @override
  Future<Either> getAttendanceById(String id) async {
    return await sl<AttendanceFirebaseService>().getAttendanceById(id);
  }

  @override
  Future<bool> isEmployeePresentToday(String employeeId, {DateTime? date}) async {
    return await sl<AttendanceFirebaseService>()
        .isEmployeePresentToday(employeeId, date: date);
  }


  @override
  Future<Either> getAttendanceByEmployeeAndDateRange(String employeeId, DateTime start, DateTime end) async{
    return await sl<AttendanceFirebaseService>().getAttendanceByEmployeeAndDateRange(employeeId, start, end);
  }



  @override
  Future<Either> updateAttendanceStatus(
      String attendanceId,
      String status,
      String reason,
      ) async {

    return await sl<AttendanceFirebaseService>()
        .updateAttendanceStatus(
      attendanceId,
      status,
      reason,
    );
  }

}