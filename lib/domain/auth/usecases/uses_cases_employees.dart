import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/domain/auth/repository/employees_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddEmployeeUseCase implements UseCase<Either, Employees> {

  @override
  Future<Either> call({Employees? params}) async {
    return await sl<EmployeesRepository>().addEmployee(params!);
  }
}
class GetEmployeeUseCase implements UseCase<Either, void> {

  @override
  Future<Either> call({void params}) async {
    return await sl<EmployeesRepository>().getAllEmployees();
  }
}
class UpdateEmployeeUseCase implements UseCase<Either, Map<String, dynamic>> {

  @override
  Future<Either> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final employee = params['employee'] as Employees;
    return await sl<EmployeesRepository>().updateEmployee(id, employee);
  }
}


class DeleteEmployeerUseCase implements UseCase<Either, String> {
  
  @override
  Future<Either> call({String? params}) async {
    return await sl<EmployeesRepository>().deleteEmployee(params!);
  }
}
class GetEmployeerByProjectIdUseCase implements UseCase<Either, String> {
  final EmployeesRepository repository;

  GetEmployeerByProjectIdUseCase({required this.repository});

  @override
  Future<Either> call({String? params}) async {
    return await repository.getEmployeeByProjectId(params!);
  }
}
class GetUsersUseCase implements UseCase<Either, void> {

  @override
  Future<Either> call({void params}) async {
    return await sl<EmployeesRepository>().getAllUsers();
  }
}
