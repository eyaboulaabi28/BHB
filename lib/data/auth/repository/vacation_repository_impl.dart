import 'package:app_bhb/data/auth/models/vacation_model.dart';
import 'package:app_bhb/data/auth/source/vacation_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/vacation_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class VacationRepositoryImpl extends VacationRepository {


  @override
  Future<Either<String, Vacation>> addVacation(Vacation vacation) async {
    final result = await sl<VacationFirebaseService>().addVacation(vacation);
    return result.fold(
          (l) => Left(l),
          (r) => Right(vacation),
    );
  }

  @override
  Future<Either<String, void>> deleteVacation(String id) async{
    return await sl<VacationFirebaseService>().deleteVacation(id);

  }

  @override
  Future<Either<String, List<Vacation>>> getAllVacation() async{
    return await sl<VacationFirebaseService>().getAllVacation();

  }

}