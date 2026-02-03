import 'package:app_bhb/data/auth/models/date_model.dart';
import 'package:app_bhb/domain/auth/repository/date_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';



class AddDateUseCase implements UseCase<Either,Date> {
  @override
  Future<Either> call({Date? params}) async {
    return await sl<DateRepository>().addDate(params!);
  }
}
class GetDateUseCase implements UseCase<Either, void> {
  final DateRepository _repo;

  GetDateUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllDate();
  }
}
class GetDateByIdUseCase implements UseCase<Either, String> {
  final DateRepository _repository;

  GetDateByIdUseCase(this._repository);

  @override
  Future<Either> call({String? params}) async {
    return await _repository.getDateById(params!);
  }
}
class UpdateDateUseCase implements UseCase<Either, Map<String, dynamic>> {
  @override
  Future<Either> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final date = params['date'] as Date;
    return await sl<DateRepository>().updateDate(id, date);
  }
}