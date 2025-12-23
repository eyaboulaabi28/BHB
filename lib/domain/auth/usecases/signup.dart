import 'package:app_bhb/core/usecase/usecase.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/domain/auth/repository/auth_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class SignupUseCase implements UseCase<Either,UserCreationReq>{


  @override
  Future<Either> call({UserCreationReq ? params})  async{

   return await sl<AuthRepository>().singup(params!);
  }

}