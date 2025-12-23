class CommentsProject{

  String? id;
  String? projectId;
  String? nameComment;
  String? description;
  DateTime? createdAt;

  CommentsProject({
    this.id,
    this.projectId,
    this.nameComment,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'nameComment': nameComment,
      'description':description,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  factory CommentsProject.fromMap(String id, Map<String, dynamic> map) {
    return CommentsProject(
      id: id,
      projectId: map['projectId'],
      nameComment: map['nameComment'],
      description:map['description'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }


}