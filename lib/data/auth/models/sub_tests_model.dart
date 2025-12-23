class SubTest {
  String? _id;
  String? _operationalsTestId;
  String? _subTestName;
  String? _status;

  // Constructeur
  SubTest({
    String? id,
    String? operationalsTestId,
    String? subTestName,
    String? status,
  })  : _id = id,
        _operationalsTestId= operationalsTestId,
        _subTestName = subTestName,
        _status = status;


  String? get id => _id;
  String? get operationalsTestId => _operationalsTestId;
  String? get subTestName=> _subTestName;
  String? get status => _status;

  set id(String? value) => _id = value;
  set operationalsTestId(String? value) => _operationalsTestId = value;
  set subTestName(String? value) => _subTestName = value;
  set status(String? value) => _status = value;

  Map<String, dynamic> toMap() {
    return {
      'operationalsTestId': _operationalsTestId,
      'subTestName': _subTestName,
      'status': _status,
    };
  }

  factory SubTest.fromMap(String id, Map<String, dynamic> map) {
    return SubTest(
      id: id,
      operationalsTestId: map['operationalsTestId'],
      subTestName: map['subTestName'],
      status: map['status'],
    );
  }
}
