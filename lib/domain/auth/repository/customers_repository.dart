import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:dartz/dartz.dart';

abstract class CustomerRepository {
  Future<Either> addCustomer(Customers customer);
  Future<Either> getAllCustomers();
  Future<Either> updateCustomer(String id, Customers customer);
  Future<Either> deleteCustomers(String id);
}
