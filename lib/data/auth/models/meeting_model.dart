import 'package:cloud_firestore/cloud_firestore.dart';


class Meeting {
  String? id;
  String? titleMeeting;
  String? description;
  String? type;
  DateTime? dateMeeting;
  String? nameCustomer;
  String? uidCustomer;
  String? nameEmployee;
  String? uidEmployee;
  String? nameEngineer;
  String? uidEngineer;
  List<String>? imageUrls;
  String? signatureUrl;
  String? customerPhone;
  List<Map<String, String>>? imageUrlsWithRemarks;
  Meeting({
    this.id,
    this.titleMeeting,
    this.description,
    this.type,
    DateTime? dateMeeting,
    this.nameCustomer,
    this.uidCustomer,
    this.nameEmployee,
    this.uidEmployee,
    this.nameEngineer,
    this.uidEngineer,
    this.imageUrls,
    this.signatureUrl,
    this.imageUrlsWithRemarks,
    this.customerPhone,
  }) : dateMeeting = dateMeeting ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleMeeting': titleMeeting,
      'description': description,
      'type': type,
      'dateMeeting': dateMeeting?.toIso8601String(),
      'nameCustomer': nameCustomer,
      'uidCustomer': uidCustomer,
      'nameEmployee': nameEmployee,
      'uidEmployee': uidEmployee,
      'nameEngineer': nameEngineer,
      'uidEngineer': uidEngineer,
      'imageUrls': imageUrls,
      'signatureUrl': signatureUrl,
      'customerPhone': customerPhone,
      'imageUrlsWithRemarks': imageUrlsWithRemarks,



    };
  }

  factory Meeting.fromMap(String id, Map<String, dynamic> map) {
    return Meeting(
      id: id,
      titleMeeting: map['titleMeeting'],
      description: map['description'],
      type: map['type'],
      dateMeeting: map['dateMeeting'] is Timestamp
          ? (map['dateMeeting'] as Timestamp).toDate()
          : map['dateMeeting'] is String
          ? DateTime.tryParse(map['dateMeeting'])
          : null,
      nameCustomer: map['nameCustomer'],
      uidCustomer: map['uidCustomer'],
      nameEmployee: map['nameEmployee'],
      uidEmployee: map['uidEmployee'],
      nameEngineer: map['nameEngineer'],
      uidEngineer: map['uidEngineer'],
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : null,
      signatureUrl: map['signatureUrl'],
      customerPhone: map['customerPhone'],
      imageUrlsWithRemarks: map['imageUrlsWithRemarks'] != null
          ? (map['imageUrlsWithRemarks'] as List)
          .map((e) => Map<String, String>.from(e))
          .toList()
          : null,
    );
  }

}
