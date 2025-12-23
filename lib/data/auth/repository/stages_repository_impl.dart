import 'package:app_bhb/data/auth/models/stages_model.dart';
import 'package:app_bhb/data/auth/source/stages_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/stages_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class StagesRepositoryImpl extends StagesRepository {


  @override
  Future<Either<String, String>> addStage(Stage stage) async {
  return await sl<StagesFirebaseService>().addStage(stage);
  }

  @override
  Future<Either> getAllStages()  async{
    return await sl<StagesFirebaseService>().getAllStages();

  }

  @override
  Future<Either<String, Unit>> updateStageStatus(Stage stage) async{
    return await sl<StagesFirebaseService>().updateStageStatus(stage!);

  }

}