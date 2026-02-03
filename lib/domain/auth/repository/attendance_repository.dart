import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:dartz/dartz.dart';

abstract class AttendanceRepository {
  Future<Either> addAttendance(Attendance attendance);
  Future<Either> getAllAttendance();
  Future<Either> getAttendanceById(String id);
  Future<Either> getAttendanceByEmployeeAndMonth(String employeeId, DateTime month,);

}