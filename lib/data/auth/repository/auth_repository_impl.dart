


import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/data/auth/models/user_signin_req.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either> singup(UserCreationReq user) async {
    return await sl<AuthFirebaseService>().singup(user);
  }
  @override
  Future<Either> getRoles()  async{
    return await sl<AuthFirebaseService>().getRoles();
  }
  @override
  Future<Either> signin(UserSigninReq user) async {
    return await sl<AuthFirebaseService>().signin(user);
  }
  @override
  Future<Either> sendPasswordResetEmail(String email)  async{
    return await sl<AuthFirebaseService>().sendPasswordResetEmail(email);
  }
  @override
  Future<Either> getUserProfile(String uid) async {
    return await sl<AuthFirebaseService>().getUserProfile(uid);
  }
  @override
  Future<Either> updateUserProfile(String uid, Map<String,dynamic> data) async {
    return await sl<AuthFirebaseService>().updateUserProfile(uid, data);
  }
}