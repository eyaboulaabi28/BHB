import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/domain/auth/repository/customers_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddCustomerUseCase implements UseCase<Either, Customers> {


  @override
  Future<Either> call({Customers? params}) async {
    return await sl<CustomerRepository>().addCustomer(params!);
  }
}
  class GetCustomerUseCase implements UseCase<Either, void> {
  @override
  Future<Either> call({void params}) async {
  return await sl<CustomerRepository>().getAllCustomers();
  }
}

class UpdateCustomerUseCase implements UseCase<Either, Map<String, dynamic>> {
  @override
  Future<Either> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final customer = params['customer'] as Customers;
    return await sl<CustomerRepository>().updateCustomer(id, customer);
  }
}

class DeleteCustomerUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call({String? params}) async {
    return await sl<CustomerRepository>().deleteCustomers(params!);
  }
}
