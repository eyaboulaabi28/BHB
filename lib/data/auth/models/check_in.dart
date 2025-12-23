import 'package:cloud_firestore/cloud_firestore.dart';

class DailyCheckIn {
  String? id;
  String? engineerId;
  String? tasks;
  String? presence;
  String? hoursStart;
  String? hoursEnd;
  String? hoursTotal;
  String? status;
  String? numberDay;
  DateTime? createdAt;

  DailyCheckIn({
    this.id,
    this.engineerId,
    this.presence,
    this.hoursStart ,
    this.hoursEnd ,
    this.hoursTotal ,
    this.tasks,
    this.status,
    this.numberDay,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DailyCheckIn.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parsedDate;

    final rawDate = map['createdAt'];

    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    } else if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    }

    return DailyCheckIn(
      id: id,
      engineerId: map['engineerId'],
      presence: map['presence'],
      hoursStart: map['hoursStart'],
      hoursEnd: map['hoursEnd'],
      hoursTotal: map['hoursTotal'],
      tasks: map['tasks'],
      status: map['status'],
      numberDay: map['numberDay'],
      createdAt: parsedDate,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'engineerId': engineerId,
      'presence': presence,
      'hoursEnd': hoursEnd,
      'hoursStart': hoursStart,
      'hoursTotal': hoursTotal,
      'tasks': tasks,
      'status': status,
      'numberDay': numberDay,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
// Méthode copyWith pour mettre à jour des champs spécifiques
  DailyCheckIn copyWith({
    String? engineerId,
    String? tasks,
    String? presence,
    String? hoursStart,
    String? hoursEnd,
    String? hoursTotal,
    String? status,
    String? numberDay,
    DateTime? createdAt,
  }) {
    return DailyCheckIn(
      engineerId: engineerId ?? this.engineerId,
      tasks: tasks ?? this.tasks,
      presence: presence ?? this.presence,
      hoursStart: hoursStart ?? this.hoursStart,
      hoursEnd: hoursEnd ?? this.hoursEnd,
      hoursTotal: hoursTotal ?? this.hoursTotal,
      status: status ?? this.status,
      numberDay: numberDay ?? this.numberDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }

}
