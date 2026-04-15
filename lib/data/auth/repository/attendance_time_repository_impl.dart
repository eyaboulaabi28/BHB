import 'package:app_bhb/data/auth/models/attendance_time_model.dart';
import 'package:app_bhb/data/auth/source/attendance_time_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/attendance_time_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class AttendanceTimeRepositoryImpl extends AttendanceTimeRepository {



  @override
  Future<Either> updateAttendanceTime(String id, AttendanceTime attendanceTime)async {// TODO: implement updateAttendanceTime
    return await sl<AttendanceTimeFirebaseService>().updateAttendanceTime(id, attendanceTime);

  }

  @override
  Future<Either> getAttendanceTime()  async{
    return await sl<AttendanceTimeFirebaseService>().getAttendanceTime();

  }


}
