
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/data/auth/models/user_signin_req.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthFirebaseService {
  Future<Either> singup(UserCreationReq user) ;
  Future<Either> signin(UserSigninReq user) ;
  Future<Either> getRoles() ;
  Future<Either>sendPasswordResetEmail(String email);
  Future<Either> getUserProfile(String uid);
  Future<Either> updateUserProfile(String uid, Map<String, dynamic> data);
}
class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either> singup(UserCreationReq user) async {
    try {
      var returnData = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: user.email!,
          password: user.password!);
    await  FirebaseFirestore.instance.collection('Users').doc(
        returnData.user!.uid
      ).set({
        'firstName':user.firstName,
        'lastName': user.lastName,
        'email':user.email,
        'password':user.password,
        'phone':user.phone,
        'role':user.role,
        'status': user.role == "engineer" ? "pending" : "approved",
      'latitude': user.latitude,
      'longitude': user.longitude,
    });
    return const Right('Sign up was successfull');
    } on FirebaseAuthException catch(e) {
      String message = '' ;
      if(e.code == 'weak-password'){
        message= 'The password provided is too weak';
      }else if (e.code =='email-already-in-use'){
        message='An account already exists with that email.';
      }
      return Left(message);
    }
  }
  @override
  Future<Either> getRoles() async {
    try{
      var returnData = await  FirebaseFirestore.instance.collection('Roles').get();
      return  Right(returnData.docs);
    }catch(e){return Left('Please try again');}
  }

  @override
  Future<Either> signin(UserSigninReq user) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: user.email!,
        password: user.password!,
      );

      final uid = credential.user!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        return Left("Compte utilisateur introuvable");
      }

      final data = userDoc.data()!;
      final role = data['role'];
      final status = data['status'];

      // ❌ bloquer engineer non approuvé
      if (role == "engineer" && status != "approved") {
        await FirebaseAuth.instance.signOut();
        return Left("حسابك قيد المراجعة من طرف الإدارة");
      }

      return const Right('SignIn was successful');
    } on FirebaseAuthException catch (e) {
      return Left("Email ou mot de passe incorrect");
    }
  }


  @override
  Future<Either> sendPasswordResetEmail(String email) async {
    try{
      await  FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return const Right('Password reset email is sent');
    }catch(e){
      return Left('Please try again');
    }
  }

  @override
  Future<Either> getUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      print('Fetching user UID: $uid');
      print('Doc exists: ${doc.exists}');
      print('Doc data: ${doc.data()}');
      if (doc.exists && doc.data() != null) {
        return Right(doc.data());
      } else {
        return Left('User not found or data is empty');
      }
    } catch (e) {
      return Left(e.toString());
    }
  }


  @override
  Future<Either> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update(data);
      return Right('Profile updated');
    } catch (e) {
      return Left(e.toString());
    }
  }
 }