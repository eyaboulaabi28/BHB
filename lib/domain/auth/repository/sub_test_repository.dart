import 'package:app_bhb/data/auth/models/sub_tests_model.dart';
import 'package:dartz/dartz.dart';

abstract class SubTestRepository {
  Future<Either<String, Unit>> addSubTest(SubTest test);
  Future<Either> getAllSubTests();
  Future<Either<String, Unit>> updateSubTestStatus(SubTest test);

}