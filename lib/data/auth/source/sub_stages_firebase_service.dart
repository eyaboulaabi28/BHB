import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class SubStagesFirebaseService {
  Future<Either<String, Unit>> addSubStage(SubStage subStage);
  Future<Either> getAllSubStages();
  Future<Either<String, Unit>> updateSubStageStatus(SubStage subStage);


}

class SubStagesFirebaseServiceImpl extends SubStagesFirebaseService {
  final _substageCollection = FirebaseFirestore.instance.collection('substages');

  @override
  Future<Either<String, Unit>> addSubStage(SubStage subStage) async {
    try {
      if (subStage.stageId== null || subStage.stageId!.isEmpty) {
        return left("L'ID du Stage  est requis pour ajouter une étape.");
      }
      final subStageData = subStage.toMap();
      await _substageCollection.add(subStageData);
      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }

  @override
  Future<Either> getAllSubStages() async {
    try {
      final snapshot = await _substageCollection.get();
      final project = snapshot.docs
          .map((doc) => SubStage.fromMap(doc.id, doc.data()))
          .toList();
      return Right(project);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> updateSubStageStatus(SubStage subStage) async{

    try {
      if (subStage.id == null || subStage.id!.isEmpty) {
        return left("ID du SubStage requis");
      }
      await _substageCollection.doc(subStage.id).update({
        'subStageStatus': subStage.subStageStatus,
      });
      return right(unit);
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }


}