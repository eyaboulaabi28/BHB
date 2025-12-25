class Tasks {
  final String? id;
  final String? description;
  final String? notes;
  final List<String>? imagesBefore;
  final List<String>? imagesAfter;
  final String? subStageId;
  final String? projectId;
  final String? floorId;
  Tasks({
    this.id,
    this.description,
    this.notes,
    this.imagesBefore,
    this.imagesAfter,
    this.subStageId,
    this.projectId,
    this.floorId,

  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'notes': notes,
      'imagesBefore': imagesBefore,
      'imagesAfter': imagesAfter,
      'subStageId': subStageId,
      'projectId': projectId,
      'floorId': floorId,

    };
  }

  factory Tasks.fromMap(String id, Map<String, dynamic> map) {
    return Tasks(
      id: id,
      description: map['description'],
      notes: map['notes'],
      imagesBefore: List<String>.from(map['imagesBefore'] ?? []),
      imagesAfter: List<String>.from(map['imagesAfter'] ?? []),
      subStageId: map['subStageId'],
      projectId: map['projectId'],
      floorId: map['floorId'],

    );
  }
}
