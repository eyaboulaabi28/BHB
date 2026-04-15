class EvaluationEngineer {
  String? id;
  String? idProject;
  String? idEngineer;
  String? nameEngineer;

  int totalScore;

  Map<String, StepEvaluation> steps;

  EvaluationEngineer({
    this.id,
    this.idProject,
    this.idEngineer,
    this.nameEngineer,
    this.totalScore = 0,
    this.steps = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'idProject': idProject,
      'idEngineer': idEngineer,
      'nameEngineer': nameEngineer,
      'totalScore': totalScore,
      'steps': steps.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory EvaluationEngineer.fromMap(String id, Map<String, dynamic> map) {
    return EvaluationEngineer(
      id: id,
      idProject: map['idProject'],
      idEngineer: map['idEngineer'],
      nameEngineer: map['nameEngineer'],
      totalScore: map['totalScore'] ?? 0,
      steps: (map['steps'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, StepEvaluation.fromMap(v)),
      ),
    );
  }
}
class StepEvaluation {
  int score;
  String status;

  StepEvaluation({
    this.score = 0,
    this.status = "pending",
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'status': status,
    };
  }

  factory StepEvaluation.fromMap(Map<String, dynamic> map) {
    return StepEvaluation(
      score: map['score'] ?? 0,
      status: map['status'] ?? "pending",
    );
  }
}