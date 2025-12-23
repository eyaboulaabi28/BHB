
import 'package:app_bhb/data/auth/models/ElectronicSignatureModel.dart';

abstract class SignatureRepository {
  Future<void> addSignature(ElectronicSignatureModel model);
}
