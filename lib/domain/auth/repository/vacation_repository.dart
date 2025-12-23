import 'package:app_bhb/data/auth/models/vacation_model.dart';
import 'package:dartz/dartz.dart';


abstract class VacationRepository {
  Future<Either<String, Vacation>> addVacation(Vacation vacation);
  Future<Either<String, List<Vacation>>> getAllVacation();
  Future<Either<String, void>> deleteVacation(String id);

}
