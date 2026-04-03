import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/data/auth/models/comments_project.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/source/comments_project_firebase_service.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_comments_project.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
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
  late final CreateNotificationUseCase _createNotificationUseCase;
  String? engineerName;
  bool isLoading = true;
  Map<int, int> stepsScores = {};
  int selectedTaskScore = -1;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    engineerName = widget.project.engineerName;
    isLoading = false;
  }

  int calculateCardScore(int indexOffset, int numberOfSteps) {
    int total = 0;
    for (int i = 0; i < numberOfSteps; i++) {
      int score = stepsScores[indexOffset + i] ?? 0;
      total += score;
    }
    return total;
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
            steps: [
              StepItem(
                text: "التواصل مع العميل لتحديد موعد فحص الموقع",
                note: "نصائح : تنسيق موعد الزياره قبل 3-4 ايام مع العميل"
              ),
              StepItem(
                text: "دراسة المخططات وتحليل العوائق المحتمله في الموقع",
                note: "مهم : التاكيد على اعتماد المخطط من العميل عبر التوقيع على المخطط او تاكيد الاعتماد عبر رساله واتس اب",
              ),
              StepItem(
                text: "التحديد و التأشير للسباكة و الكهرباء ",
                note: "نصائح : يفضل التنسيق مع العميل ويصبح متواجد في الموقع لاخذ الاستشارات الهندسيه في السلبيات و الايجابيات بناء من خبرتنا الهندسيه في التخصص ",
              ),
              StepItem(
                text: "طلب المواد من العميل",
                note: "مهم : طلب كميه لاتقل عن 50٪ ولا تزيد عن 70٪ لمرحله (العظم ومابعد العظم)",
              ),
            ],
            indexOffset: 0,
            scores: stepsScores,
            onScoreChanged: (index, score) {
              setState(() {
                stepsScores[index] = score;
              });
            },
          ),
          ModernStepCard(
            title: "بداية المرحلة التسليم إلى الفني",
            steps: [
              StepItem(
                text: "اضافه صور التسليم في التقرير",
                note: "نصائح: صور جميع نقاط المرحلة للتاكد من تحليل المسارات قبل تسليم المهام للفني (قبل العمل)",
              ),
              StepItem(
                text: "التأكد من عدم وجود عوائق قبل تسليم المهام في الموقع",
                note: "مثل: نقص ادوات العمل او نقص المواد او عدم توصيل المعلومة للفني",
              ),
              StepItem(
                text: "فحص جودة العمل و المقاسات و المستوى و الميول في الموقع بشكل دوري",
                note: "مهم: لا يقل عن 4 ايام في الاسبوع",
              ),
            ],
            scores: stepsScores,
            indexOffset: 100,
            onScoreChanged: (index, score) {
              setState(() {
                stepsScores[index] = score;
              });
            },
          ),
          ModernStepCard(
            title: "نهاية المرحلة الاستلام النهائي",
            steps: [
              StepItem(
                text: "اضافة صور الاستلام في التقرير",
                note: "نصائح: صور كل نقطة في المرحلة أثناء استلام المهام اليومية للفني (بعد العمل)",
              ),
              StepItem(
                text: "فحص جميع نقاط المرحلة",
                note: "مهم جدا: فحص المبنى بالكامل والتركيز على جميع الأقسام بدون تخطي أي جزء",
              ),
              StepItem(
                text: "التواصل مع العميل لتسليم الموقع",
                note: "نصائح: الاستفسار عن المدة المتوقعة لحجز الموعد القادم",
              ),
            ],
            scores: stepsScores,
            indexOffset: 200,
            onScoreChanged: (index, score) {
              setState(() {
                stepsScores[index] = score;
              });
            },
          ),
          const SizedBox(height: 16),

          // 🔥 Score total
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
                mainAxisSize: MainAxisSize.min, // Pour que le container ne prenne que la place nécessaire
                children: [
                  const Icon(Icons.emoji_events, color: Colors.redAccent), // Icône
                  const SizedBox(width: 8),
                  Text(
                    "النتيجة الإجمالية: ${stepsScores.values.fold(0, (sum, value) => sum + value)}",
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),        ],
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
  final String text;
  final String note;

  StepItem({
    required this.text,
    required this.note,
  });
}
class ModernStepItem extends StatelessWidget {
  final StepItem step;
  final int index;
  final int selectedScore;
  final Function(int) onScoreSelected;

  const ModernStepItem({
    super.key,
    required this.step,
    required this.index,
    required this.selectedScore,
    required this.onScoreSelected,
  });

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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              ModernChoiceChip(
                label: "ممتاز",
                score: 100,
                isSelected: selectedScore == 100,
                onSelected: () => onScoreSelected(100),
              ),

              ModernChoiceChip(
                label: "جيد",
                score: 50,
                isSelected: selectedScore == 50,
                onSelected: () => onScoreSelected(50),
              ),

              ModernChoiceChip(
                label: "سيء",
                score: 0,
                isSelected: selectedScore == 0,
                onSelected: () => onScoreSelected(0),
              ),
            ],
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
  final Function(int index, int score) onScoreChanged;
  final int indexOffset;
  const ModernStepCard({
    super.key,
    required this.title,
    required this.steps,
    required this.scores,
    required this.onScoreChanged,
    required this.indexOffset,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics, color: Colors.blueAccent),
              ),
              Expanded(
                child: Text(
                  "$title — نتيجة: $cardScore",  // 🔥 Score affiché ici
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

          /// STEPS
          ...steps.asMap().entries.map((entry) {
            int index = entry.key;
            int realIndex = index + indexOffset;

            return ModernStepItem(
              step: entry.value,
              index: realIndex,
              selectedScore: scores[realIndex] ?? -1,
              onScoreSelected: (score) {
                onScoreChanged(realIndex, score);
              },
            );
          }),
        ],
      ),
    );
  }
}