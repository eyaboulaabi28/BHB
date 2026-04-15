import 'package:app_bhb/data/auth/models/attendance_time_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:dartz/dartz.dart';

abstract class AttendanceTimeRepository {

  Future<Either> updateAttendanceTime(String id, AttendanceTime attendanceTime);
  Future<Either> getAttendanceTime();

}