import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


abstract class CustomerFirebaseService {
  Future<Either> addCustomer(Customers customer);
  Future<Either> getAllCustomers();
  Future<Either> updateCustomer(String id, Customers customer);
  Future<Either> deleteCustomers(String id);
}

class CustomerFirebaseServiceImpl extends CustomerFirebaseService {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<Either> addCustomer(Customers customer)  async{
    try {
      final doc = await _firestore.collection('Users').add(customer.toMap());
      return Right(doc.id);
    } catch (e) {
      return Left('Error adding Customer: $e');
    }
  }

  @override
  Future<Either> deleteCustomers(String id) async {
    try {
      await _firestore.collection('Users').doc(id).delete();
      return const Right('customer deleted successfully');
    } catch (e) {
      return Left('Error deleting customer: $e');
    }
  }

  @override
  Future<Either> getAllCustomers() async {
    try {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'customer')
          .get();

      final customers = querySnapshot.docs
          .map((doc) => Customers.fromMap(doc.id, doc.data()))
          .toList();

      return Right(customers);
    } catch (e) {
      return Left('Error fetching customer: $e');
    }
  }



  @override
  Future<Either> updateCustomer(String id, Customers customer) async {
    try {
      await _firestore.collection('Users').doc(id).update(customer.toMap());
      return const Right('Customer updated successfully');
    } catch (e) {
      return Left('Error updating customer: $e');
    }
  }


}