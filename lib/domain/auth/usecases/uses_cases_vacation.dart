import 'package:app_bhb/data/auth/models/vacation_model.dart';
import 'package:app_bhb/domain/auth/repository/vacation_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddVacationUseCase implements UseCase<Either<String, Vacation>, Vacation> {
  @override
  Future<Either<String, Vacation>> call({Vacation? params}) async {
    return await sl<VacationRepository>().addVacation(params!);
  }
}
class GetAllVacationUseCase implements UseCase<Either<String, List<Vacation>>, void> {
  @override
  Future<Either<String, List<Vacation>>> call({void params}) async {
    return await sl<VacationRepository>().getAllVacation();
  }
}
class DeleteVacationUseCase implements UseCase<Either<String, void>, String> {
  @override
  Future<Either<String, void>> call({String? params}) async {
    return await sl<VacationRepository>().deleteVacation(params!);
  }
}