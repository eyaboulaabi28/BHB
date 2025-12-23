import 'package:app_bhb/data/auth/models/operationals_test_model.dart';
import 'package:app_bhb/data/auth/source/operationals_test_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/operationals_test_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class OperationalsTestRepositoryImpl extends OperationalsTestRepository {

  

  @override
  Future<Either> getAllOperationalsTest() async{
    return await sl<OperationalsTestFirebaseService>().getAllOperationalsTest();
  }

  @override
  Future<Either<String, Unit>> updateOperationalTestStatus(OperationalsTest operation) async{
    return await sl<OperationalsTestFirebaseService>().updateOperationalTestStatus(operation);
  }

  @override
  Future<Either<String, OperationalsTest>> addOperationalTest(OperationalsTest operation) async {
    return await sl<OperationalsTestFirebaseService>().addOperationalTest(operation);

  }

}