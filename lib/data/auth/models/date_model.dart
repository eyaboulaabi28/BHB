enum DateStatus {
  pending,
  late,
  completed,
}

class Date {
  String? id;
  String? customerName;
  DateTime? createdAt;
  String? uidCustomer;
  String? typeDate;
  DateStatus status;

  Date({
    this.id,
    this.typeDate,
    this.customerName,
    this.uidCustomer,
    DateTime? createdAt,
    this.status = DateStatus.pending, // 👈 default
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'typeDate': typeDate,
      'uidCustomer': uidCustomer,
      'createdAt': createdAt?.toIso8601String(),
      'status': status.name, // 👈 نحفظها String
    };
  }

  factory Date.fromMap(String id, Map<String, dynamic> map) {
    return Date(
      id: id,
      customerName: map['customerName'],
      typeDate: map['typeDate'],
      uidCustomer: map['uidCustomer'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      status: DateStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => DateStatus.pending,
      ),
    );
  }
}

