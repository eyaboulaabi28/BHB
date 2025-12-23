import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:dartz/dartz.dart';

abstract class EngineerRepository {
  Future<Either> addEngineer(Engineer engineer);
  Future<Either> getAllEngineers();
  Future<Either> updateEngineer(String id, Engineer engineer);
  Future<Either> deleteEngineer(String id);
  Future<bool> isEmailUsed(String email);
}
