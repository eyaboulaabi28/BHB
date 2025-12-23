import 'package:app_bhb/core/usecase/usecase.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/data/auth/models/user_signin_req.dart';
import 'package:app_bhb/domain/auth/repository/auth_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class SendPasswordUseCase implements UseCase<Either,String>{
  @override
  Future<Either> call({String ? params}) async {
    return await sl<AuthRepository>().sendPasswordResetEmail(params!);

  }


}