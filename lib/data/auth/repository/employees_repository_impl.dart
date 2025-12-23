import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/source/employees_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/employees_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class EmployeesRepositoryImpl extends EmployeesRepository {


  @override
  Future<Either> addEmployee(Employees employee) async{
    return await sl<EmployeesFirebaseService>().addEmployee(employee);

  }

  @override
  Future<Either> deleteEmployee(String id) async{
    return await sl<EmployeesFirebaseService>().deleteEmployee(id);

  }

  @override
  Future<Either> getAllEmployees() async {
    return await sl<EmployeesFirebaseService>().getAllEmployees();

  }

  @override
  Future<Either> updateEmployee(String id, Employees employee) async {

    return await sl<EmployeesFirebaseService>().updateEmployee(id, employee);
  }

  @override
  Future<Either> getEmployeeByProjectId(String projectId)  async{
    return await sl<EmployeesFirebaseService>().getEmployeeByProjectId(projectId);

  }

  @override
  Future<Either> getAllUsers() async {
    return await sl<EmployeesFirebaseService>().getAllUsers();

  }
}
