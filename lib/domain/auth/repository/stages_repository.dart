import 'package:app_bhb/data/auth/models/stages_model.dart';
import 'package:dartz/dartz.dart';

abstract class StagesRepository {
  Future<Either<String, String>> addStage(Stage stage);
  Future<Either> getAllStages();
  Future<Either<String, Unit>> updateStageStatus(Stage stage);
}