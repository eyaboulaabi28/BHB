import 'package:cloud_firestore/cloud_firestore.dart';

class DailyTasks {

  String? id;
  String? projectId;
  String? engineerId;
  String? titleTask;
  String? description ;
  String? status;
  DateTime? createdAt;
  String? duration;

  DailyTasks({
    this.id,
    this.projectId,
    this.engineerId,
    this.titleTask,
    this.description,
    this.status,
    this.duration,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'engineerId': engineerId,
      'titleTask': titleTask,
      'description':description,
      'status':status,
      'duration':duration,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }
  factory DailyTasks.fromMap(String id, Map<String, dynamic> map) {
    return DailyTasks(
      id: id,
      projectId: map['projectId'],
      engineerId: map['engineerId'],
      titleTask: map['titleTask'],
      description:map['description'],
      status: map['status'],
      duration: map['duration'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

}