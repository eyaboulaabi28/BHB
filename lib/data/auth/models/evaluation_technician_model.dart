class EvaluationTechnician {
  String? id;
  String? idProject;
  String? idEngineer;
  String? nameEngineer;
  String? idEmployee;
  String? nameEmployee;
  String? description;

  EvaluationTechnician({
    this.id,
    this.idProject,
    this.idEngineer,
    this.nameEngineer,
    this.description,
    this.nameEmployee,
    this.idEmployee,

  }) ;
  Map<String, dynamic> toMap() {
    return {
      'idProject': idProject,
      'idEngineer': idEngineer,
      'nameEngineer': nameEngineer,
      'description': description,
      'nameEmployee': nameEmployee,
      'idEmployee': idEmployee,
    };
  }

  factory EvaluationTechnician.fromMap(String id, Map<String, dynamic> map) {
    return EvaluationTechnician(
      id: id,
      idProject: map['idProject'],
      idEngineer: map['idEngineer'],
      nameEngineer: map['nameEngineer'] ,
      description:map['description'],
      nameEmployee: map['nameEmployee'] ,
      idEmployee:map['idEmployee'],
    );
  }
}