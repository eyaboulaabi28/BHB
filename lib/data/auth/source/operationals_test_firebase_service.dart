import 'package:app_bhb/data/auth/models/operationals_test_model.dart';
import 'package:app_bhb/data/auth/models/stages_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class OperationalsTestFirebaseService {

  Future<Either<String, OperationalsTest>> addOperationalTest(OperationalsTest operation);


  Future<Either> getAllOperationalsTest();
  Future<Either<String, Unit>> updateOperationalTestStatus(OperationalsTest operation);

}
class OperationalsTestFirebaseServiceImpl extends OperationalsTestFirebaseService {

  final _operationalsTestCollection = FirebaseFirestore.instance.collection('operationalsTest');

  @override
  Future<Either<String, OperationalsTest>> addOperationalTest(OperationalsTest operation) async {
    try {
      if (operation.projectId == null || operation.projectId!.isEmpty) {
        return left("L'ID du projet (projectId) est requis pour ajouter un test.");
      }

      final docRef = await _operationalsTestCollection.add(operation.toMap());

      final newTest = OperationalsTest(
        id: docRef.id,
        projectId: operation.projectId,
        operationalsTestName: operation.operationalsTestName,
        status: operation.status,
      );

      return right(newTest);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }

  @override
  Future<Either> getAllOperationalsTest() async{
    try {
      final snapshot = await _operationalsTestCollection.get();
      final operationalsTest = snapshot.docs
          .map((doc) => OperationalsTest.fromMap(doc.id, doc.data()))
          .toList();
      return Right(operationalsTest);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> updateOperationalTestStatus(OperationalsTest operation) async{
    try {
      if (operation.id == null || operation.id!.isEmpty) {
        return left("L'ID du operation est requis pour la mise à jour.");
      }

      await _operationalsTestCollection.doc(operation.id).update({
        'status': operation.status,
      });

      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }
}