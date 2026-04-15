import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/data/auth/models/evaluation_engineer_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import '../../../service_locator.dart';

class ProjectEvaluationEngineer extends StatefulWidget {
  final Project project;
  final String? ownerId;
  const ProjectEvaluationEngineer({super.key, required this.project, required this.ownerId});
  @override
  State<ProjectEvaluationEngineer> createState() => _ProjectEvaluationEngineerState();
}

class _ProjectEvaluationEngineerState extends State<ProjectEvaluationEngineer> {
  UserCreationReq user = UserCreationReq();
  late final CreateNotificationUseCase _createNotificationUseCase;
  String? engineerName;
  bool isLoading = true;
  Map<int, int> stepsScores = {};
  int selectedTaskScore = -1;
  bool get isAdmin => user.role == "admin";
  String? selectedEngineer;
  List<EvaluationEngineer> evaluations = [];
  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    engineerName = widget.project.engineerName;
    isLoading = false;
    _loadCurrentUserProfile();
    loadEvaluations();
  }
  Future<void> _loadCurrentUserProfile() async {
    final fbUser = FirebaseAuth.instance.currentUser;

    if (fbUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(fbUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          user = UserCreationReq.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
  }
  Future<void> loadEvaluations() async {
    final doc = await FirebaseFirestore.instance
        .collection('evaluationEngineer')
        .doc("${widget.project.id}_${widget.ownerId}")
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    setState(() {
      stepsScores.clear();

      final steps = Map<String, dynamic>.from(data['steps'] ?? {});

      steps.forEach((key, value) {
        final index = int.tryParse(key);
        if (index == null) return;
        stepsScores[index] = value['score'];
      });
    });
  }
  int calculateTotalScore() {
    int total = 0;
    bool hasVeryBad = false;

    for (var score in stepsScores.values) {
      if (score == -5) {
        hasVeryBad = true;
      } else {
        total += score;
      }
    }

    // نضيف -5 مرة واحدة فقط
    if (hasVeryBad) {
      total -= 5;
    }

    return total;
  }

  Future<void> updateEvaluation({
    required String projectId,
    required String engineerId,
    required String stepKey,
    required int score,
    required String stepText,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('evaluationEngineer')
        .doc("${projectId}_$engineerId");

    final doc = await docRef.get();

    Map<String, dynamic> steps = {};

    if (doc.exists) {
      steps = Map<String, dynamic>.from(doc.data()?['steps'] ?? {});
    }

    String status = _getStatusFromScore(score);

    steps[stepKey] = {
      "score": score,
      "status": status,
      "text": stepText,
    };

    int total = 0;
    bool hasVeryBad = false;

    for (var s in steps.values) {
      int val = (s["score"] as num?)?.toInt() ?? 0;

      if (val == -5) {
        hasVeryBad = true;
      } else {
        total += val;
      }
    }

    if (hasVeryBad) total -= 5;

    await docRef.set({
      "idProject": projectId,
      "idEngineer": engineerId,
      "nameEngineer": widget.project.engineerName,
      "steps": steps,
      "totalScore": total,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  String _getStatusFromScore(int score) {
    switch (score) {
      case 10:
        return "ممتاز";
      case 7:
        return "جيد جدا";
      case 5:
        return "جيد";
      case 3:
        return "مقبول";
      case 0:
        return "سيء";
      case -5:
        return "سيء جدا";
      default:
        return "غير محدد";
    }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "📘 تقييم المهندسين",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// CHAMP INGENIEUR RESPONSABLE
          if (!isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F7FA), Color(0xFFE4E9F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.engineering,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "المهندس المسؤول: ${engineerName ?? 'غير محدد'}",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          /// ==================== CARD CHAMP "تسليم المهام" MODERNE ====================
          SizedBox(height: 8),
          ModernStepCard(
            title: "الدراسة الفنية للمرحلة",
            isAdmin: (user.role == "admin"),
            steps: [
              StepItem(
                  id: "0",
                text: "التواصل مع العميل لتحديد موعد فحص الموقع",
                note: "نصائح : تنسيق موعد الزياره قبل 3-4 ايام مع العميل"
              ),
              StepItem(
                id: "1",
                text: "دراسة المخططات وتحليل العوائق المحتمله في الموقع",
                note: "مهم : التاكيد على اعتماد المخطط من العميل عبر التوقيع على المخطط او تاكيد الاعتماد عبر رساله واتس اب",
              ),
              StepItem(
                id: "2",
                text: "التحديد و التأشير للسباكة و الكهرباء ",
                note: "نصائح : يفضل التنسيق مع العميل ويصبح متواجد في الموقع لاخذ الاستشارات الهندسيه في السلبيات و الايجابيات بناء من خبرتنا الهندسيه في التخصص ",
              ),
              StepItem(
                id: "3",
                text: "طلب المواد من العميل",
                note: "مهم : طلب كميه لاتقل عن 50٪ ولا تزيد عن 70٪ لمرحله (العظم ومابعد العظم)",
              ),
            ],
            indexOffset: 0,
            scores: stepsScores,
            onScoreChanged: (index, score, stepText) async {
              setState(() {
                stepsScores[index] = score;
              });

              await updateEvaluation(
                projectId: widget.project.id!,
                engineerId: widget.ownerId!,
                stepKey: index.toString(),
                score: score,
                stepText: stepText,
              );
            },
          ),
          ModernStepCard(
            title: "بداية المرحلة التسليم إلى الفني",
            isAdmin: (user.role == "admin"),
            steps: [
              StepItem(
                id: "4",
                text: "اضافه صور التسليم في التقرير",
                note: "نصائح: صور جميع نقاط المرحلة للتاكد من تحليل المسارات قبل تسليم المهام للفني (قبل العمل)",
              ),
              StepItem(
                id: "5",
                text: "التأكد من عدم وجود عوائق قبل تسليم المهام في الموقع",
                note: "مثل: نقص ادوات العمل او نقص المواد او عدم توصيل المعلومة للفني",
              ),
              StepItem(
                id: "6",
                text: "فحص جودة العمل و المقاسات و المستوى و الميول في الموقع بشكل دوري",
                note: "مهم: لا يقل عن 4 ايام في الاسبوع",
              ),
            ],
            scores: stepsScores,
            indexOffset: 100,
            onScoreChanged: (index, score, stepText) async {
              setState(() {
                stepsScores[index] = score;
              });

              await updateEvaluation(
                projectId: widget.project.id!,
                engineerId: widget.ownerId!,
                stepKey: index.toString(),
                score: score,
                stepText: stepText,
              );
            },
          ),
          ModernStepCard(
            title: "نهاية المرحلة الاستلام النهائي",
            isAdmin: (user.role == "admin"),
            steps: [
              StepItem(
                id: "7",
                text: "اضافة صور الاستلام في التقرير",
                note: "نصائح: صور كل نقطة في المرحلة أثناء استلام المهام اليومية للفني (بعد العمل)",
              ),
              StepItem(
                id: "8",
                text: "فحص جميع نقاط المرحلة",
                note: "مهم جدا: فحص المبنى بالكامل والتركيز على جميع الأقسام بدون تخطي أي جزء",
              ),
              StepItem(
                id: "9",
                text: "التواصل مع العميل لتسليم الموقع",
                note: "نصائح: الاستفسار عن المدة المتوقعة لحجز الموعد القادم",
              ),
            ],
            scores: stepsScores,
            indexOffset: 200,
              onScoreChanged: (index, score, stepText) async {
                setState(() {
                  stepsScores[index] = score;
                });

                await updateEvaluation(
                  projectId: widget.project.id!,
                  engineerId: widget.ownerId!,
                  stepKey: index.toString(),
                  score: score,
                  stepText: stepText,
                );
              }
          ),
          const SizedBox(height: 16),

          // 🔥 Score total
          if (isAdmin)
            Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// SCORE
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(
                        "النتيجة: ${calculateTotalScore()}",
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  /// BUTTON موافق
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      await updateEvaluation(
                        projectId: widget.project.id!,
                        engineerId: widget.ownerId!,
                        stepKey: "final",
                        score: calculateTotalScore(),
                        stepText: "TOTAL",
                      );

                      CustomSnackBar.show(
                        context,
                        message: "تم حفظ التقييم النهائي",
                        type: SnackBarType.success,
                      );
                    },
                    child: const Text(
                      "موافق",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),    ],
      ),
    );
  }
}
class ModernChoiceChip extends StatelessWidget {
  final String label;
  final int score;
  final bool isSelected;
  final VoidCallback onSelected;

  const ModernChoiceChip({
    super.key,
    required this.label,
    required this.score,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onSelected,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
class StepItem {
  final String id;
  final String text;
  final String note;

  StepItem({
    required this.id,
    required this.text,
    required this.note,
  });
}
class ModernStepItem extends StatelessWidget {
  final StepItem step;
  final int index;
  final int selectedScore;
  final Function(int) onScoreSelected;
  final bool isAdmin;
  const ModernStepItem({
    super.key,
    required this.step,
    required this.index,
    required this.selectedScore,
    required this.onScoreSelected,
    required this.isAdmin,
  });

  static const Map<String, int> scoreOptions = {
    "ممتاز": 10,
    "جيد جدا": 7,
    "جيد": 5,
    "مقبول": 3,
    "سيء": 0,
    "سيء جدا": -5,
  };

  String? get selectedLabel {
    return scoreOptions.entries
        .firstWhere(
          (e) => e.value == selectedScore,
      orElse: () => const MapEntry("", -1),
    )
        .key;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            step.note,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 12),

          /// 🔥 REPLACEMENT: Chips → Select Field
          if (isAdmin)
            NewRoundSelectField(
              hintText: "اختر التقييم",
              options: scoreOptions.keys.toList(),
              controller: TextEditingController(
                text: selectedLabel ?? "",
              ),
              onChanged: (value) {
                if (value == null) return;
                final score = scoreOptions[value] ?? 0;
                onScoreSelected(score);
              },
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "التقييم مخفي (غير متاح لهذا المستخدم)",
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class ModernStepCard extends StatelessWidget {
  final String title;
  final List<StepItem> steps;
  final Map<int, int> scores;
  final Function(int index, int score, String stepText) onScoreChanged;  final int indexOffset;
  final bool isAdmin;

  const ModernStepCard({
    super.key,
    required this.title,
    required this.steps,
    required this.scores,
    required this.onScoreChanged,
    required this.indexOffset,
    required this.isAdmin,
  });

  int get cardScore {
    int total = 0;
    for (int i = 0; i < steps.length; i++) {
      int score = scores[i + indexOffset] ?? 0;
      total += score;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F7FA), Color(0xFFE4E9F0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          /// ================= HEADER =================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics, color: Colors.blueAccent),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  "$title — نتيجة: $cardScore",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ================= STEPS =================
          ...steps.asMap().entries.map((entry) {
            int index = entry.key;
            int realIndex = index + indexOffset;

            return ModernStepItem(
              step: entry.value,
              index: realIndex,
              selectedScore: scores[realIndex] ?? -1,
              isAdmin: isAdmin,
              onScoreSelected: (score) {
                onScoreChanged(realIndex, score, entry.value.text);
              },
            );
          }),
          const SizedBox(height: 10),

          /// ================= FIXED FOOTER SPACE =================
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.only(top: 12),

            /// 🔥 مهم: نفس الارتفاع دائمًا
            height: 60,
            child: isAdmin
                ? const SizedBox() // select موجود داخل steps
                : Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "التقييم غير متاح لهذا المستخدم",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}