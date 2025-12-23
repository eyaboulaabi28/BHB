

import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/source/engineers_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/engineers_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class EngineerRepositoryImpl extends EngineerRepository {

  @override
  Future<Either> addEngineer(Engineer engineer) async {
    return await sl<EngineerFirebaseService>().addEngineer(engineer);
  }

  @override
  Future<Either> getAllEngineers() async {
    return await sl<EngineerFirebaseService>().getAllEngineers();
  }

  @override
  Future<Either> updateEngineer(String id, Engineer engineer) async {
    return await sl<EngineerFirebaseService>().updateEngineer(id, engineer);
  }

  @override
  Future<Either> deleteEngineer(String id) async {
    return await sl<EngineerFirebaseService>().deleteEngineer(id);
  }

  @override
  Future<bool> isEmailUsed(String email) async {
    return await sl<EngineerFirebaseService>().isEmailUsed(email);
  }
}
