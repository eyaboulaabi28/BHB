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

  // Score sélectionné pour تسليم المهام
  int selectedTaskScore = -1; // -1 = non sélectionné

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    engineerName = widget.project.engineerName;
    isLoading = false;
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
          /// ==================== CARD CHAMP "تسليم المهام" MODERNE ====================
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITRE AVEC ACCENT VISUEL
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "تسليم المهام",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                /// SCORE SÉLECTIONNÉ
                if (selectedTaskScore >= 0)
                  Text(
                    "نتيجة: $selectedTaskScore",
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                if (selectedTaskScore >= 0) const SizedBox(height: 16),

                /// CHOIX DES SCORES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ModernChoiceChip(
                      label: "ممتاز",
                      score: 100,
                      isSelected: selectedTaskScore == 100,
                      onSelected: () {
                        setState(() {
                          selectedTaskScore = 100;
                        });
                      },
                    ),
                    ModernChoiceChip(
                      label: "جيد",
                      score: 50,
                      isSelected: selectedTaskScore == 50,
                      onSelected: () {
                        setState(() {
                          selectedTaskScore = 50;
                        });
                      },
                    ),
                    ModernChoiceChip(
                      label: "سيء",
                      score: 0,
                      isSelected: selectedTaskScore == 0,
                      onSelected: () {
                        setState(() {
                          selectedTaskScore = 0;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }
}

/// ===================== ModernChoiceChip =====================
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