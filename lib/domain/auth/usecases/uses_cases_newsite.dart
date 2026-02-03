import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/domain/auth/repository/newSite_Repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';



class AddNewSiteUseCase implements UseCase<Either,NewSite> {
  @override
  Future<Either> call({NewSite? params}) async {
    return await sl<NewSiteRepository>().addNewSite(params!);
  }
}
class GetNewSiteUseCase implements UseCase<Either, void> {
  final NewSiteRepository _repo;

  GetNewSiteUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllNewSite();
  }
}
class GetNewSiteByIdUseCase implements UseCase<Either, String> {
  final NewSiteRepository _repository;

  GetNewSiteByIdUseCase(this._repository);

  @override
  Future<Either> call({String? params}) async {
    return await _repository.getNewSiteById(params!);
  }
}
class UpdateSiteTasksUseCase implements UseCase<Either, NewSite> {
  final NewSiteRepository _repo;

  UpdateSiteTasksUseCase(this._repo);

  @override
  Future<Either> call({NewSite? params}) async {
    if (params == null) return Left("Paramètre site manquant");
    return await _repo.addNewSite(params); // ⚠️ Ici tu peux créer une méthode dédiée update
  }
}
