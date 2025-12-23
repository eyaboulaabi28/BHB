class SettingsModel {
   String? id;
   String? workHoursCount;
   String? workStartTime;
   String? workEndTime;
   String? hourlyRate;
   String? employeeRank;

  SettingsModel({
     this.id,
     this.workHoursCount,
     this.workStartTime,
     this.workEndTime,
     this.hourlyRate,
     this.employeeRank,
  });

  Map<String, dynamic> toMap() {
    return {
      'workHoursCount': workHoursCount,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'hourlyRate': hourlyRate,
      'employeeRank': employeeRank,
    };
  }

  // Create object from Map
   factory SettingsModel.fromMap(String id, Map<String, dynamic> map) {
     return SettingsModel(
       id: id,
       workHoursCount: map['workHoursCount']?.toString() ?? '',
       workStartTime: map['workStartTime'] ?? '',
       workEndTime: map['workEndTime'] ?? '',
       hourlyRate: map['hourlyRate']?.toString() ?? '',
       employeeRank: map['employeeRank'] ?? '',
     );
   }


}
