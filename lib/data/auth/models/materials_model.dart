class Materials {
  String? id;
  String? projectId;
  String? name;
  String? unit;
  String? image;

  Materials({
    this.id,
    this.projectId,
    this.name,
    this.unit,
    this.image,

  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'image': image,
      'projectId':projectId,
    };
  }

  factory Materials.fromMap(String id, Map<String, dynamic> map) {
    return Materials(
      id: id,
      name: map['name'],
      unit: map['unit'],
      image: map['image'],
      projectId:map['projectId'],
    );
  }
}
