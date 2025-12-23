class Stage {
  String? _id;
  String? _projectId;
  String? _stageName;
  String? _status;

  // Constructeur
  Stage({
    String? id,
    String? projectId,
    String? stageName,
    String? status,
  })  : _id = id,
        _projectId = projectId,
        _stageName = stageName,
        _status = status;

  String? get id => _id;
  String? get projectId => _projectId;
  String? get stageName => _stageName;
  String? get status => _status;

  set id(String? value) => _id = value;
  set projectId(String? value) => _projectId = value;
  set stageName(String? value) => _stageName = value;
  set status(String? value) => _status = value;

  Map<String, dynamic> toMap() {
    return {
      'projectId': _projectId,
      'stageName': _stageName,
      'status': _status,
    };
  }

  factory Stage.fromMap(String id, Map<String, dynamic> map) {
    return Stage(
      id: id,
      projectId: map['projectId'],
      stageName: map['stageName'],
      status: map['status'],
    );
  }
}
