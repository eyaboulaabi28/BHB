import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:dartz/dartz.dart';

abstract class SubStagesRepository {
  Future<Either<String, Unit>> addSubStage(SubStage stage);
  Future<Either> getAllSubStages();
  Future<Either<String, Unit>> updateSubStageStatus(SubStage subStage);

}