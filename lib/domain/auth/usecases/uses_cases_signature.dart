
import 'package:app_bhb/data/auth/models/ElectronicSignatureModel.dart';
import 'package:app_bhb/domain/auth/repository/signature_repository.dart';

class AddElectronicSignatureUseCase {
  final SignatureRepository repository;

  AddElectronicSignatureUseCase(this.repository);

  Future<void> call(ElectronicSignatureModel model) {
    return repository.addSignature(model);
  }
}
