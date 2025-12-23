class TasksTests {
  final String? id;
  final String? notes;
  final List<String>? images;
  final String? subTestId;
  final String? projectId;

  TasksTests({
    this.id,
    this.notes,
    this.images,
    this.subTestId,
    this.projectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'notes': notes,
      'images': images,
      'subTestId': subTestId,
      'projectId': projectId,
    };
  }

  factory TasksTests.fromMap(String id, Map<String, dynamic> map) {
    return TasksTests(
      id: id,
      notes: map['notes'],
      images: List<String>.from(map['images'] ?? []),
      subTestId: map['subTestId'],
      projectId: map['projectId'],
    );
  }
}
