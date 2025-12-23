
import 'package:app_bhb/data/auth/models/contact_model.dart';

abstract class ContactRepository {
  Future<void> sendContactMessage(ContactMessage message);
}
