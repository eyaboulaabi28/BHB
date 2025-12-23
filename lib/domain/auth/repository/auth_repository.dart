import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/data/auth/models/user_signin_req.dart';
import 'package:dartz/dartz.dart';

abstract  class AuthRepository {

  Future<Either>singup (UserCreationReq  user) ;
  Future<Either>signin(UserSigninReq  user) ;
  Future<Either>getRoles () ;
  Future<Either>sendPasswordResetEmail(String email);
  Future<Either> getUserProfile(String uid);
  Future<Either> updateUserProfile(String uid, Map<String, dynamic> data);

}