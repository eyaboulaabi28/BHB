
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


abstract class EmployeesFirebaseService {

  Future<Either> addEmployee(Employees employee);
  Future<Either> getAllEmployees();
  Future<Either> updateEmployee(String id, Employees employee);
  Future<Either> deleteEmployee(String id);
  Future<Either> getEmployeeByProjectId(String projectId);
  Future<Either> getAllUsers();


}
class EmployeesFirebaseServiceImpl extends EmployeesFirebaseService {

  final _firestore = FirebaseFirestore.instance;

  @override
  Future<Either> addEmployee(Employees employee) async{
    try {
      final doc = await _firestore.collection('Users').add(employee.toMap());
      return Right(doc.id);
    } catch (e) {
      return Left('Error adding employee: $e');
    }
  }

  @override
  Future<Either> deleteEmployee(String id) async{
    try {
      await _firestore.collection('Users').doc(id).delete();
      return const Right('employee deleted successfully');
    } catch (e) {
      return Left('Error deleting employee: $e');
    }
  }

  @override
  Future<Either> getAllEmployees() async{
    try {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'employee')
          .get();

      final employees = querySnapshot.docs
          .map((doc) => Employees.fromMap(doc.id, doc.data()))
          .toList();

      return Right(employees);
    } catch (e) {
      return Left('Error fetching customer: $e');
    }
  }

  @override
  Future<Either> updateEmployee(String id, Employees employee) async{
    try {
      await _firestore.collection('Users').doc(id).update(employee.toMap());
      return const Right('employee updated successfully');
    } catch (e) {
      return Left('Error updating employee: $e');
    }
  }

    @override
    Future<Either> getEmployeeByProjectId(String projectId) async {
      try {
        final querySnapshot = await _firestore
            .collection('Users')
            .where('role', isEqualTo: 'employee')
            .where('projectId', isEqualTo: projectId)
            .get();

        final employees = querySnapshot.docs
            .map((doc) => Employees.fromMap(doc.id, doc.data()))
            .toList();

        return Right(employees);
      } catch (e) {
        return Left('Error fetching employees by projectId: $e');
      }
    }

  @override
  Future<Either> getAllUsers() async{
    try {
      final querySnapshot = await _firestore
          .collection('Users')
          .get();

      final employees = querySnapshot.docs
          .map((doc) => Employees.fromMap(doc.id, doc.data()))
          .toList();

      return Right(employees);
    } catch (e) {
      return Left('Error fetching customer: $e');
    }
  }
  }




