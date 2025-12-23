import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/data/auth/source/sub_stages_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/sub_stages_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class SubStagesRepositoryImpl extends SubStagesRepository {


  @override
  Future<Either<String, Unit>> addSubStage(SubStage subStage) async {
    return await sl<SubStagesFirebaseService>().addSubStage(subStage);
  }

  @override
  Future<Either> getAllSubStages()  async{
    return await sl<SubStagesFirebaseService>().getAllSubStages();

  }

  @override
  Future<Either<String, Unit>> updateSubStageStatus(SubStage subStage) async {
    return await sl<SubStagesFirebaseService>().updateSubStageStatus(subStage);
  }



}