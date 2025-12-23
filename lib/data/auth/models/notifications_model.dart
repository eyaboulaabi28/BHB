class NotificationsModel {
  final String title;
  final String message;
  final DateTime createdAt;
  final String? userId;
  final String? route;
  bool isRead;
  String? id;

  NotificationsModel({
    required this.title,
    required this.message,
    required this.createdAt,
    this.userId,
    this.route,
    this.id,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'route': route,
      'id': id,
      'isRead': isRead,
    };
  }

  factory NotificationsModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationsModel(
      id: id,
      title: map['title'],
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
      userId: map['userId'],
      route: map['route'],
      isRead: map['isRead'] ?? false,
    );
  }
}
