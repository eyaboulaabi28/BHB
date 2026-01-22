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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customersCollection =>
      _firestore.collection('Users');

  @override
  Future<Either> addCustomer(Customers customer) async {
    try {
      // 🔎 Vérifier unicité du numéro de téléphone
      final query = await _customersCollection
          .where('phone', isEqualTo: customer.phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Left("رقم الهاتف مستخدم بالفعل");
      }

      // ✅ Ajouter le customer
      final doc = await _customersCollection.add(customer.toMap());

      return Right(doc.id);
    } catch (e) {
      return Left(e.toString());
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