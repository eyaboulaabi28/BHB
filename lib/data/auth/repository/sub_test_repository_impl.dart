import 'package:app_bhb/data/auth/models/sub_tests_model.dart';
import 'package:app_bhb/data/auth/source/sub_test_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/sub_test_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class SubTestRepositoryImpl extends SubTestRepository {


  @override
  Future<Either<String, Unit>> addSubTest(SubTest test) async {
    return await sl<SubTestFirebaseService>().addSubTest(test);

  }

  @override
  Future<Either> getAllSubTests()async {
    return await sl<SubTestFirebaseService>().getAllSubTests();

  }

  @override
  Future<Either<String, Unit>> updateSubTestStatus(SubTest test) async{
    return await sl<SubTestFirebaseService>().updateSubTestStatus(test);

  }

}