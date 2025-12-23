
class ElectronicSignatureModel {
  final String? id;
  final String? userId;
  final String? signatureImage;
  final String? signatureImageUrl;
  final DateTime? createdAt;

  ElectronicSignatureModel({
    this.id,
    this.userId,
    this.signatureImageUrl,
    this.createdAt,
    this.signatureImage
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'signatureImageUrl': signatureImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'signatureImage':signatureImage
    };
  }

  factory ElectronicSignatureModel.fromMap(Map<String, dynamic> map) {
    return ElectronicSignatureModel(
      id: map['id'],
      userId: map['userId'],
      signatureImageUrl: map['signatureImageUrl'],
      signatureImage: map['signatureImage'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
    );
  }
}
