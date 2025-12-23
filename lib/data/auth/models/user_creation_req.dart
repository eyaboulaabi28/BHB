class UserCreationReq {
  String ? firstName ;
  String ? lastName ;
  String ? email ;
  String ? password ;
  String ? role;
  String ? phone;
  double? latitude;
  double? longitude;


  UserCreationReq({this.firstName, this.lastName, this.email, this.password,this.role,this.phone,this.latitude,
    this.longitude,});

  factory UserCreationReq.fromMap(Map<String, dynamic> map) {
    return UserCreationReq(
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      role: map['role'],
      phone: map['phone'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }
}