class Attachments {
  String? id;
  String? projectId;
  String? fileName;
  String? description;
  String? fileType;
  String? fileUrl;
  DateTime? createdAt;

  Attachments({
    this.id,
    this.projectId,
    this.fileName,
    this.fileType,
    this.fileUrl,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'fileName': fileName,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'description':description,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Attachments.fromMap(String id, Map<String, dynamic> map) {
    return Attachments(
      id: id,
      projectId: map['projectId'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      fileUrl: map['fileUrl'],
        description:map['description'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}
