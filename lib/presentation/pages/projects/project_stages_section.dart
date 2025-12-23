import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/data/auth/source/projects_firebase_service.dart';
import 'package:app_bhb/presentation/pages/projects/global_project_pdf_generator.dart';
import 'package:app_bhb/presentation/pages/projects/predefined_phases.dart';
import 'package:app_bhb/presentation/pages/projects/stage_pdf_generator.dart' hide TColor;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_bhb/common/color_extension.dart';
import '../../../service_locator.dart';
import 'project_stages_sub_section.dart';

class ProjectStagesSection extends StatefulWidget {
  final String projectId;

  const ProjectStagesSection({super.key, required this.projectId});

  @override
  State<ProjectStagesSection> createState() => _ProjectStagesSectionState();
}

class _ProjectStagesSectionState extends State<ProjectStagesSection> {
   List<Map<String, dynamic>> _stages = [];
  Map<String, dynamic> _stagesStatus = {};

  String? _userRole;


  @override
  void initState() {
    super.initState();

    _stages = predefinedPhasesStructure.map<Map<String, dynamic>>((phase) {
      return {
        ...phase,
        'subPhases': (phase['subPhases'] as List)
            .map((sub) => Map<String, dynamic>.from(sub))
            .toList(),
      };
    }).toList();

    _loadUserRole();
    _loadStagesStatus();
  }
  Future<void> _loadStagesStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    if (doc.exists) {
      setState(() {
        _stagesStatus = doc.data()?['stagesStatus'] ?? {};
        _applyStatusFromFirestore(); // 🔴 IMPORTANT
      });
    }
  }

  void _applyStatusFromFirestore() {
    for (final stage in _stages) {
      final stageId = stage['id'];
      final stageData = _stagesStatus[stageId];

      if (stageData != null) {
        stage['status'] = stageData['status'];

        for (final sub in stage['subPhases']) {
          sub['status'] =
              stageData['subStages']?[sub['id']] ?? 'en cours';
        }
      }
    }
  }

  void _onSubStageStatusChanged(
      String stageId,
      String subId,
      String newStatus,
      ) async {

    // 🔹 1. Sauvegarde Firebase
    await sl<ProjectsFirebaseService>().updateSubStageStatus(
      widget.projectId,
      stageId,
      subId,
      newStatus,
    );

    // 🔹 2. Mise à jour UI locale
    setState(() {
      for (final stage in _stages) {
        if (stage['id'] == stageId) {
          for (final sub in stage['subPhases']) {
            if (sub['id'] == subId) {
              sub['status'] = newStatus;
            }
          }

          // 🔹 Auto calcul du status du stage
          final allDone =
          stage['subPhases'].every((s) => s['status'] == 'terminé');

          stage['status'] = allDone ? 'terminé' : 'en cours';
        }
      }
    });
  }
  Future<void> _loadUserRole() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final result = await sl<AuthFirebaseService>().getUserProfile(userId);

    result.fold(
          (err) => null, // erreur ignorée ici
          (data) {
        setState(() {
          _userRole = (data['role'] as String?)?.toLowerCase();
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "📘 مراحل المشروع",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          ElevatedButton.icon(
            onPressed: () {
              GlobalStagesPdfGenerator(
                projectId: widget.projectId,
                stages: _stages,
              ).generate(context);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
            label: const Text("تقرير شامل"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
          ),

        ],
      ),
          const SizedBox(height: 20),
          if (_stages.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.timeline_outlined,
                      color: Colors.grey.shade400, size: 70),
                  const SizedBox(height: 8),
                  const Text(
                    "لم تتم إضافة أي مراحل بعد",
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),
          ..._stages.asMap().entries.map((entry) {
            final index = entry.key;
            final stage = entry.value;
            // ✅ CRÉATION CORRECTE DU PDF GENERATOR (ICI)
            final pdfGenerator = StagePdfGenerator(
              projectId: widget.projectId,
            );
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 5,height: 5,),

                    CircleAvatar(
                      radius: 22,
                      backgroundColor: TColor.primary.withOpacity(0.2),
                      child: Icon(Icons.timeline, color: TColor.primary),
                    ),
                    const SizedBox(width: 12,height: 25,),
                    Expanded(
                      child: Text(
                        "المرحلة ${index + 1} : ${stage['name']}",
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // ✅ BOUTON PDF CORRIGÉ
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf,
                          color: Colors.redAccent),
                      tooltip: "تحميل المرحلة كـ PDF",
                      onPressed: () {
                        pdfGenerator.generate(context, stage);
                      },
                    ),
                    SizedBox(width: 5,),
                    // ✅ CHECKBOX FIREBASE
                    Checkbox(
                      value: stage['status'] == 'terminé',
                      onChanged: (value) async {
                        final newStatus =
                        value! ? 'terminé' : 'en cours';

                        await sl<ProjectsFirebaseService>()
                            .updateStageStatus(
                          widget.projectId,
                          stage['id'],
                          newStatus,
                        );

                        setState(() {
                          stage['status'] = newStatus;
                          for (final sub in stage['subPhases']) {
                            sub['status'] = newStatus;
                          }
                        });
                      },
                    ),
                  ],
                ),
                children: [
                  ProjectStagesSubSectionStatic(
                    stageId: stage['id'],
                    subStages: List<Map<String, dynamic>>.from(
                        stage['subPhases']),
                    onSubStatusChanged: _onSubStageStatusChanged,
                    projectId: widget.projectId,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

}
