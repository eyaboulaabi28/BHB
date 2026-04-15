import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceTime {
  String? id;
  DateTime? startTime;
  DateTime? endTime;
  DateTime? createdAt;

  AttendanceTime({
    this.id,
    this.startTime,
    this.endTime,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 🔹 Convert object to Map (Firestore / API)
  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'createdAt': createdAt,
    };
  }

  /// 🔹 Create object from Map
  factory AttendanceTime.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceTime(
      id: id,
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : null,
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'])
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']))
          : null,

    );
  }

}
