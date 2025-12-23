class Employees {
  String? id;
  String? firstName;
  String? email;
  String? profession;
  String? phone;
  String? role;
  String? projectId;
  double? latitude;
  double? longitude;



  Employees({
    this.id,
    this.firstName,
    this.email,
    this.profession,
    this.phone,
    this.projectId,
    this.role = "employee",
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'email': email,
      'profession': profession,
      'phone': phone,
      'role': role,
      'projectId':projectId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Employees.fromMap(String id, Map<String, dynamic> map) {
    return Employees(
      id: id,
      firstName: map['firstName'],
      email: map['email'],
      profession: map['profession'],
      phone: map['phone'],
      role: map['role'],
      projectId:map['projectId'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),


    );
  }
}
