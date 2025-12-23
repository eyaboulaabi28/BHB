class Customers {
  String? id;
  String? firstName;
  String? email;
  String? type;
  String? phone;
  String? role;
  double? latitude;
  double? longitude;

  Customers({
    this.id,
    this.firstName,
    this.email,
    this.type,
    this.phone,
    this.role = "customer",
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'email': email,
      'type': type,
      'phone': phone,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Customers.fromMap(String id, Map<String, dynamic> map) {
    return Customers(
      id: id,
      firstName: map['firstName'],
      email: map['email'],
      type: map['type'],
      phone: map['phone'],
      role: map['role'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }
}
