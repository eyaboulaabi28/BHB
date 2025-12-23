class OperationalsTest {
  String? _id;
  String? _projectId;
  String? _operationalsTestName;
  String? _status;

  // Constructeur
  OperationalsTest({
    String? id,
    String? projectId,
    String? operationalsTestName,
    String? status,
  })  : _id = id,
        _projectId = projectId,
        _operationalsTestName = operationalsTestName,
        _status = status;


  String? get id => _id;
  String? get projectId => _projectId;
  String? get operationalsTestName=> _operationalsTestName;
  String? get status => _status;

  set id(String? value) => _id = value;
  set projectId(String? value) => _projectId = value;
  set operationalsTestName(String? value) => _operationalsTestName = value;
  set status(String? value) => _status = value;

  Map<String, dynamic> toMap() {
    return {
      'projectId': _projectId,
      'operationalsTestName': _operationalsTestName,
      'status': _status,
    };
  }

  factory OperationalsTest.fromMap(String id, Map<String, dynamic> map) {
    return OperationalsTest(
      id: id,
      projectId: map['projectId'],
      operationalsTestName: map['operationalsTestName'],
      status: map['status'],
    );
  }
}
