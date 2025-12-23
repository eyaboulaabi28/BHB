import 'package:app_bhb/data/auth/models/contact_model.dart';
import 'package:app_bhb/data/auth/source/contact_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/contact_repository.dart';
import 'package:app_bhb/service_locator.dart';

class ContactRepositoryImpl extends ContactRepository {

  @override
  Future<void> sendContactMessage(ContactMessage message) async{
    return await sl<ContactFirebaseService>().sendContactMessage(message);

  }


}