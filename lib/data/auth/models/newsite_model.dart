import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewSite {
  String? id;
  String? customerName;
  String? projectName;
  String? phone;
  DateTime? createdAt;
  double? latitude;
  double? longitude;
  String? nameEngineer;
  String? uidEngineer;
  SiteTask task; // 👈 Task واحد
  String? generalRemark;

  NewSite({
    this.id,
    this.customerName,
    this.projectName,
    this.phone,
    this.latitude,
    this.longitude,
    this.nameEngineer,
    this.uidEngineer,
    DateTime? createdAt,
    required this.task,
    this.generalRemark,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'projectName': projectName,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'nameEngineer': nameEngineer,
      'uidEngineer': uidEngineer,
      'generalRemark': generalRemark,
      'task': task.toMap(),
    };
  }

  factory NewSite.fromMap(String id, Map<String, dynamic> map) {
    return NewSite(
      id: id,
      customerName: map['customerName'],
      projectName: map['projectName'],
      phone: map['phone'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as Timestamp).toDate())
          : null,

      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      nameEngineer: map['nameEngineer'],
      uidEngineer: map['uidEngineer'],
      generalRemark: map['generalRemark'],
      task: map['task'] != null
          ? SiteTask.fromMap(map['task'])
          : SiteTask(items: []),

    );
  }
}

