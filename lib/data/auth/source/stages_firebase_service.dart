import 'package:app_bhb/data/auth/models/stages_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class StagesFirebaseService {
  Future<Either<String, String>> addStage(Stage stage);
  Future<Either> getAllStages();
  Future<Either<String, Unit>> updateStageStatus(Stage stage);


}

class StagesFirebaseServiceImpl extends StagesFirebaseService {
  final _stageCollection = FirebaseFirestore.instance.collection('stages');

  @override
  Future<Either<String, String>> addStage(Stage stage) async {
    try {
      if (stage.projectId == null || stage.projectId!.isEmpty) {
        return left("L'ID du projet (projectId) est requis pour ajouter une étape.");
      }
      final stageData = stage.toMap();
      final docRef = await _stageCollection.add(stageData);
      return right(docRef.id); // retourne l'ID du document créé
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }


  @override
  Future<Either> getAllStages() async {
    try {
      final snapshot = await _stageCollection.get();
      final project = snapshot.docs
          .map((doc) => Stage.fromMap(doc.id, doc.data()))
          .toList();
      return Right(project);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> updateStageStatus(Stage stage) async {
    try {
      if (stage.id == null || stage.id!.isEmpty) {
        return left("L'ID du stage est requis pour la mise à jour.");
      }

      await _stageCollection.doc(stage.id).update({
        'status': stage.status,
      });

      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }

}