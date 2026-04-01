import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/domain/auth/repository/attendance_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';



class AddAttendanceUseCase implements UseCase<Either, Attendance> {
  @override
  Future<Either> call({Attendance? params}) async {
    // Vérifier si l'employé est déjà présent aujourd'hui
    final alreadyPresent = await sl<AttendanceRepository>()
        .isEmployeePresentToday(params!.employeeId!);

    if (alreadyPresent) {
      return Left("لا يمكن إضافة حضور أكثر من مرة في نفس اليوم");
    }

    return await sl<AttendanceRepository>().addAttendance(params);
  }
}
class GetAttendanceUseCase implements UseCase<Either, void> {
  final AttendanceRepository _repo;

  GetAttendanceUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllAttendance();
  }
}
class GetAttendanceByIdUseCase implements UseCase<Either, String> {
  final AttendanceRepository _repository;

  GetAttendanceByIdUseCase(this._repository);

  @override
  Future<Either> call({String? params}) async {
    return await _repository.getAttendanceById(params!);
  }
}
class GetAttendanceByEmployeeAndMonthUseCase implements UseCase<Either, Map<String, dynamic>> {

  final AttendanceRepository repo;

  GetAttendanceByEmployeeAndMonthUseCase(this.repo);

  @override
  Future<Either> call({Map<String, dynamic>? params}) {
    return repo.getAttendanceByEmployeeAndDateRange(
      params!['employeeId'],
      params['start'], // <-- utilise 'start' et non 'startDate'
      params['end'],   // <-- utilise 'end' et non 'endDate'
    );

  }
}
class IsEmployeePresentTodayUseCase {
  Future<bool> call(String employeeId, {DateTime? date}) async {
    return await sl<AttendanceRepository>()
        .isEmployeePresentToday(employeeId, date: date);
  }
}



