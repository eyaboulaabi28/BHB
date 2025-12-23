class Engineer {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? role;
  double? latitude;
  double? longitude;
  String? status;
  Engineer({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.role = "engineer",
    this.latitude,
    this.longitude,
    this.status,
  });
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone':phone,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
  factory Engineer.fromMap(String id, Map<String, dynamic> map) {
    return Engineer(
      id: id,
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phone:map['phone'],
      role: map['role'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      status: map['status'],
    );
  }
}
