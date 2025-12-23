import 'package:app_bhb/data/auth/models/operationals_test_model.dart';
import 'package:app_bhb/domain/auth/repository/operationals_test_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';

class AddOperationalsTestUseCase implements UseCase<Either, OperationalsTest> {
  final OperationalsTestRepository repository;

  AddOperationalsTestUseCase(this.repository);

  @override
  Future<Either<String, OperationalsTest>> call({OperationalsTest? params}) async {
    return await repository.addOperationalTest(params!);
  }
}

class GetOperationalsTestUseCase implements UseCase<Either, void> {
  final OperationalsTestRepository _repo;

  GetOperationalsTestUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllOperationalsTest();
  }
}
class UpdateOperationalsTestStatusUseCase implements UseCase<Either, OperationalsTest> {
  final OperationalsTestRepository repository;

  UpdateOperationalsTestStatusUseCase(this.repository);

  @override
  Future<Either> call({OperationalsTest? params}) async {
    if (params == null) {
      return left("OperationalsTest non fourni");
    }
    return await repository.updateOperationalTestStatus(params!);
  }
}