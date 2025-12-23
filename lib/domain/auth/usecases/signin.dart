import 'package:app_bhb/core/usecase/usecase.dart';
import 'package:app_bhb/data/auth/models/user_signin_req.dart';
import 'package:app_bhb/domain/auth/repository/auth_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class SigninUseCase implements UseCase<Either,UserSigninReq>{


  @override
  Future<Either> call({UserSigninReq ? params}) {

    return sl<AuthRepository>().signin(params!);

  }
}