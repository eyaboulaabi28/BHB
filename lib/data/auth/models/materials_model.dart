class Materials {
  String? id;
  String? projectId;
  String? stage;
  String? unit;
  String? description;
  String? engineerId;

  Materials({
    this.id,
    this.projectId,
    this.stage,
    this.unit,
    this.description,
    this.engineerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'stage': stage,
      'unit': unit,
      'description': description,
      'engineerId': engineerId,
    };
  }

  factory Materials.fromMap(String id, Map<String, dynamic> map) {
    return Materials(
      id: id,
      projectId: map['projectId'],
      stage: map['stage'],
      unit: map['unit'],
      description: map['description'],
      engineerId: map['engineerId'],
    );
  }
}
