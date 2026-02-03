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
  Future<Either> getAttendanceByEmployeeAndMonth(String employeeId, DateTime month)async {
    return await sl<AttendanceFirebaseService>().getAttendanceByEmployeeAndMonth(employeeId,month);
  }
}