class SubStage {
  String? _id;
  String? _stageId;
  String? _subStageName;
  String? _subStageStatus;

  // Constructeur
  SubStage({
    String? id,
    String? stageId,
    String? subStageName,
    String? subStageStatus,
  })  : _id = id,
        _stageId = stageId,
        _subStageName = subStageName,
        _subStageStatus = subStageStatus;

  // === Getters ===
  String? get id => _id;
  String? get stageId => _stageId;
  String? get subStageName => _subStageName;
  String? get subStageStatus => _subStageStatus;

  // === Setters ===
  set id(String? value) => _id = value;
  set stageId(String? value) => _stageId = value;
  set subStageName(String? value) => _subStageName = value;
  set subStageStatus(String? value) => _subStageStatus = value;

  // === Conversion en Map ===
  Map<String, dynamic> toMap() {
    return {
      'stageId': _stageId,
      'subStageName': _subStageName,
      'subStageStatus': _subStageStatus,
    };
  }

  // === Construction à partir d'une Map ===
  factory SubStage.fromMap(String id, Map<String, dynamic> map) {
    return SubStage(
      id: id,
      stageId: map['stageId'],
      subStageName: map['subStageName'],
      subStageStatus: map['subStageStatus'],
    );
  }
}
