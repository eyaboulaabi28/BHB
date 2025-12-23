import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/data/auth/source/customers_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/customers_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class CustomerRepositoryImpl extends CustomerRepository {

  @override
  Future<Either> addCustomer(Customers customer) async {
    return await sl<CustomerFirebaseService>().addCustomer(customer);

  }

  @override
  Future<Either> deleteCustomers(String id) async {
    return await sl<CustomerFirebaseService>().deleteCustomers(id);

  }

  @override
  Future<Either> getAllCustomers() async {
    return await sl<CustomerFirebaseService>().getAllCustomers();

  }



  @override
  Future<Either> updateCustomer(String id, Customers customer) async {

    return await sl<CustomerFirebaseService>().updateCustomer(id, customer);

  }

}