import 'package:app_bhb/data/auth/models/sub_tests_model.dart';
import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class SubTestFirebaseService {
  Future<Either<String, Unit>> addSubTest(SubTest test);
  Future<Either> getAllSubTests();
  Future<Either<String, Unit>> updateSubTestStatus(SubTest test);
}
class SubTestFirebaseServiceImpl extends SubTestFirebaseService {
  final _subTestsCollection = FirebaseFirestore.instance.collection('subTests');



  @override
  Future<Either<String, Unit>> addSubTest(SubTest test) async{
    try {
      if (test.operationalsTestId== null || test.operationalsTestId!.isEmpty) {
        return left("L'ID du test  est requis pour ajouter un test.");
      }
      final subTestData = test.toMap();
      await _subTestsCollection.add(subTestData);
      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }

  @override
  Future<Either> getAllSubTests() async{
    try {
      final snapshot = await _subTestsCollection.get();
      final test = snapshot.docs
          .map((doc) => SubTest.fromMap(doc.id, doc.data()))
          .toList();
      return Right(test);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> updateSubTestStatus(SubTest test) async{
    try {
      if (test.id == null || test.id!.isEmpty) {
        return left("ID du SubStage requis");
      }
      await _subTestsCollection.doc(test.id).update({
        'status': test.status,
      });
      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }


}