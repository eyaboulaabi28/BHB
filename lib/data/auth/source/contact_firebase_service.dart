
import 'package:app_bhb/data/auth/models/contact_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ContactFirebaseService {

  Future<void> sendContactMessage(ContactMessage message);


}
class ContactFirebaseServiceImpl extends ContactFirebaseService {

  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendContactMessage(ContactMessage message) async {
    // 🔹 On écrit dans la collection 'mail' pour l'extension
    await _firestore.collection('mail').add({
      'to': 'eyaboulaabi1@gmail.com', // Email destinataire
      'template': 'default',          // Template défini dans Mailgun
      'message': {
        'subject': 'رسالة جديدة من التطبيق',
        'text': """
Nom: ${message.name}
Phone: ${message.phone}
Email: ${message.email}
Message: ${message.reason}
""",
        'html': """
<p><b>Nom:</b> ${message.name}</p>
<p><b>Phone:</b> ${message.phone}</p>
<p><b>Email:</b> ${message.email}</p>
<p><b>Message:</b> ${message.reason}</p>
"""
      },
    });
  }
}
