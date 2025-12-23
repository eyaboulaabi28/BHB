import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:dartz/dartz.dart';

abstract class EmployeesRepository {
  Future<Either> addEmployee(Employees employee);
  Future<Either> getAllEmployees();
  Future<Either> updateEmployee(String id, Employees employee);
  Future<Either> deleteEmployee(String id);
  Future<Either> getEmployeeByProjectId(String projectId);
  Future<Either> getAllUsers();


}
