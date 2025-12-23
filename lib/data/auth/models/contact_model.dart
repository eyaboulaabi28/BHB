class ContactMessage {
  final String name;
  final String phone;
  final String email;
  final String reason;

  ContactMessage({
    required this.name,
    required this.phone,
    required this.email,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'reason': reason,
    'timestamp': DateTime.now(),
  };
}
