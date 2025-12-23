class Vacation {

  String? id;
  String? nameVacation;
  DateTime? dateVacation;

  Vacation({
    this.id,
    this.nameVacation,
    DateTime? dateVacation,
  }) : dateVacation = dateVacation ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameVacation': nameVacation,
      'dateVacation': dateVacation?.toIso8601String(),
    };
  }
  factory Vacation.fromMap(String id, Map<String, dynamic> map) {
    return Vacation(
      id: id,
      nameVacation: map['nameVacation'],
      dateVacation: map['dateVacation'] != null ? DateTime.parse(map['dateVacation']) : null,
    );
  }


}