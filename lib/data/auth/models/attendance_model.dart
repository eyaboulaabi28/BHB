class Attendance {
  String? id;
  String? employeeName;
  DateTime? startTime;
  DateTime? endTime;
  double? waitingHours;
  double? overtimeHours;
  String? signatureUrl;
  String? customerName;
  DateTime? createdAt;
  String? employeeId;
  String? notes;

  Attendance({
    this.id,
    this.employeeId,
    this.employeeName,
    this.startTime,
    this.endTime,
    this.waitingHours,
    this.overtimeHours,
    this.signatureUrl,
    this.customerName,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 🔹 Convert object to Map (Firestore / API)
  Map<String, dynamic> toMap() {
    return {
      'employeeName': employeeName,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'waitingHours': waitingHours,
      'overtimeHours': overtimeHours,
      'signatureUrl': signatureUrl,
      'customerName': customerName,
      'employeeId': employeeId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// 🔹 Create object from Map
  factory Attendance.fromMap(String id, Map<String, dynamic> map) {
    return Attendance(
      id: id,
      employeeName: map['employeeName'],
      employeeId: map['employeeId'],
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : null,
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'])
          : null,
      waitingHours: map['waitingHours'] != null
          ? (map['waitingHours'] as num).toDouble()
          : null,
      overtimeHours: map['overtimeHours'] != null
          ? (map['overtimeHours'] as num).toDouble()
          : null,
      signatureUrl: map['signatureUrl'],
      customerName: map['customerName'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      notes: map['notes'],

    );
  }
}
