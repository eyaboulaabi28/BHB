

import 'package:app_bhb/data/auth/models/ElectronicSignatureModel.dart';
import 'package:app_bhb/data/auth/source/signature_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/signature_repository.dart';

import '../../../service_locator.dart';

class SignatureRepositoryImp implements SignatureRepository {

  @override
  Future<void> addSignature(ElectronicSignatureModel model) async{
    return await sl<SignatureFirebaseService>().addSignature(model);
  }

}
