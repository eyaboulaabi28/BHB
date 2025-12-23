import 'package:app_bhb/core/usecase/usecase.dart';
import 'package:app_bhb/domain/auth/repository/auth_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetRoleSUseCase implements UseCase<Either,dynamic>{


  @override
  Future<Either> call({dynamic params})  async{

    return await sl<AuthRepository>().getRoles();
  }

}

class GetUserProfileUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call({String? params}) {
    return sl<AuthRepository>().getUserProfile(params!);
  }
}
class UpdateUserProfileUseCase implements UseCase<Either, UpdateUserParams> {
  @override
  Future<Either> call({UpdateUserParams? params}) {
    return sl<AuthRepository>().updateUserProfile(params!.uid, params.data);
  }
}

class UpdateUserParams {
  final String uid;
  final Map<String, dynamic> data;

  UpdateUserParams(this.uid, this.data);
}
