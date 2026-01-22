import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/projects/add_task_dialog.dart';
import 'package:app_bhb/presentation/pages/projects/sub_stage_tasks_list.dart';
import 'package:flutter/material.dart';

import '../../../service_locator.dart';

class ProjectStagesSubSectionStatic extends StatefulWidget {
  final String stageId; // 🔴 AJOUT
  final List<Map<String, dynamic>> subStages;
  final String projectId;
  final String projectName;

  final Function(
      String stageId,
      String subId,
      String newStatus,
      ) onSubStatusChanged;

  const ProjectStagesSubSectionStatic({
    super.key,
    required this.stageId,
    required this.subStages,
    required this.projectId,
    required this.onSubStatusChanged,
    required this.projectName,
  });

  @override
  State<ProjectStagesSubSectionStatic> createState() =>
      _ProjectStagesSubSectionStaticState();
}


class _ProjectStagesSubSectionStaticState extends State<ProjectStagesSubSectionStatic> {

  final GetProjectByIdUseCase _getProjectByIdUseCase = sl<GetProjectByIdUseCase>();
  String? _projectNameFromFirebase;

  @override
  void initState() {
    super.initState();
    _loadProjectName();

  }

  Future<void> _loadProjectName() async {
    final result = await _getProjectByIdUseCase.call(
      params: widget.projectId,
    );

    result.fold(
          (failure) {
        debugPrint('❌ Erreur récupération projet: $failure');
      },
          (project) {
        debugPrint(
          '📌 Project ID: ${project.id} | Project Name: ${project.projectName}',
        );
        setState(() {
          _projectNameFromFirebase = project.projectName;
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: widget.subStages.asMap().entries.map((entry) {
          final index = entry.key;
          final sub = entry.value;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),

            /// 🔽 SubStage expandable مثل Stage
            child:
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.only(bottom: 12),

              /// 🔹 HEADER
              title: Row(
                children: [
                  /// رقم SubStage
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  /// اسم SubStage
                  Expanded(
                    child:
                    Text(
                      sub['name'],
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: sub['status'] == 'terminé'
                            ? Colors.grey
                            : Colors.black,
                        decoration: sub['status'] == 'terminé'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),

                  ),
                  Checkbox(
                    value: sub['status'] == 'terminé',
                    onChanged: (value) {
                      final newStatus = value! ? 'terminé' : 'en cours';

                      setState(() {
                        sub['status'] = newStatus;
                      });

                      // 🔴 NOTIFIER LE PARENT
                      widget.onSubStatusChanged(
                        widget.stageId,
                        sub['id'],
                        newStatus,
                      );
                    },
                  ),

                  /// ➕ Ajouter Task
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.green),
                    tooltip: "أضف مهمة",
                    onPressed: () {
                      final fakeSubStage = SubStage(
                        id: sub['id'],
                        stageId: widget.stageId,
                        subStageName: sub['name'],
                        subStageStatus: "en cours",
                      );

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        builder: (_) => AddTaskDialog(

                          subStage: fakeSubStage,
                          projectId: widget.projectId,
                          projectName: _projectNameFromFirebase!,
                        ),
                      );
                    },
                  ),
                ],
              ),

              /// 🔹 BODY → TASKS
              children: [
                SizedBox(
                  height: 250,
                  child: SubStageTasksList(
                    subStageId: sub['id'],
                    projectId: widget.projectId,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
