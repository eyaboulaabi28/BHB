import 'package:app_bhb/data/auth/models/sub_tests_model.dart';
import 'package:app_bhb/domain/auth/repository/sub_test_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';

class AddSubTestUseCase implements UseCase<Either, SubTest> {
  final SubTestRepository repository;

  AddSubTestUseCase(this.repository);

  @override
  Future<Either> call({SubTest? params}) async {
    return await repository.addSubTest(params!);
  }
}
class GetSubTestUseCase implements UseCase<Either, void> {
  final SubTestRepository _repo;

  GetSubTestUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllSubTests();
  }
}
class UpdateSubTestStatusUseCase implements UseCase<Either, SubTest> {
  final SubTestRepository repository;

  UpdateSubTestStatusUseCase(this.repository);

  @override
  Future<Either> call({SubTest? params}) async {
    if (params == null) {
      return left("SubTest non fourni");
    }
    return await repository.updateSubTestStatus(params!);
  }
}
