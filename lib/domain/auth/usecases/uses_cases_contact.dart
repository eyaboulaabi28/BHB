import 'package:app_bhb/data/auth/models/contact_model.dart';
import 'package:app_bhb/domain/auth/repository/contact_repository.dart';

class SendContactMessageUseCase {
  final ContactRepository repository;

  SendContactMessageUseCase(this.repository);

  Future<void> call(ContactMessage message) async {
    return repository.sendContactMessage(message);
  }
}