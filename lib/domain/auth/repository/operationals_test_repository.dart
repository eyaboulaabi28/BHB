import 'package:app_bhb/data/auth/models/operationals_test_model.dart';
import 'package:dartz/dartz.dart';

abstract class OperationalsTestRepository {
  Future<Either<String, OperationalsTest>> addOperationalTest(OperationalsTest operation);
  Future<Either> getAllOperationalsTest();
  Future<Either<String, Unit>> updateOperationalTestStatus(OperationalsTest operation);
}