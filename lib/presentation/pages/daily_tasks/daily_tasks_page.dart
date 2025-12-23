import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_daily_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/daily_tasks/add_daily_task_modal.dart';

import 'package:flutter/material.dart';

import '../../../service_locator.dart';


class DailyTasksPage extends StatefulWidget {
  final String selectedType;

  const DailyTasksPage({super.key, required this.selectedType});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  int _selectedIndex = 0;
  List<DailyTasks> dailyTasks = [];
  bool isLoading = true;
  List<Engineer> engineers = [];
  List<Project> projects = [];
  final getAllDailyTasksUC = sl<GetAllDailyTasksUseCase>();

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
    _loadEngineers();
    _loadProjects();
  }
  Future<void> _loadDailyTasks() async {
    setState(() => isLoading = true);

    final result = await getAllDailyTasksUC();

    result.fold(
          (error) {
        CustomSnackBar.show(context, message: error, type: SnackBarType.error);
      },
          (data) {
        setState(() {
          dailyTasks = data;
        });
      },
    );

    setState(() => isLoading = false);
  }


  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold( (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)), ); }

  Future<void> _loadProjects() async {
    final result = await sl<GetProjectUseCase>().call();
    result.fold( (error) => debugPrint("Error loading projects"),
          (list) => setState(() => projects = List<Project>.from(list)), ); }




  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF2F4F3),
        appBar: AppBar(
          backgroundColor: TColor.primary,
          elevation: 0,
          title: const SizedBox(),
        ),

        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 25, top: 20),
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Center(
                child: Text(
                  "إدارة الجداول اليومية",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: dailyTasks.length,
                itemBuilder: (context, index) {
                  final task = dailyTasks[index];

                  final engineerName = engineers.firstWhere(
                        (e) => e.id?.trim() == task.engineerId?.trim(),
                    orElse: () => Engineer(id: null, firstName: "مهندس مجهول"),
                  ).firstName;
                  final projectName = projects.firstWhere(
                        (p) => p.id?.trim() == task.projectId?.trim(),
                    orElse: () => Project(id: null, projectName: "مشروع مجهول"),
                  ).projectName;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: TColor.primary.withOpacity(0.2),
                                child: Icon(Icons.calendar_today, color: TColor.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.titleTask ?? "عنوان المهمة",
                                      style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Infos projet & ingénieur
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(Icons.description, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.description ?? "",
                                    style: const TextStyle(
                                        fontFamily: 'Tajawal', fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.engineering, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    engineerName ?? "",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.apartment, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    projectName ?? "",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(Icons.timer, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${task.duration ?? ""} أيام",
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        task.createdAt != null
                                            ? "${task.createdAt!.day}/${task.createdAt!.month}/${task.createdAt!.year}"
                                            : "-",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: task.status == "مكتملة"
                                          ? Colors.green[100]
                                          : task.status == "متأخرة"
                                          ? Colors.red[100]
                                          : task.status == "مازالت لم تبدأ"
                                          ? Colors.blue[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task.status ?? "-",
                                      style: TextStyle(
                                        color: task.status == "مكتملة"
                                            ? Colors.green[800]
                                            : task.status == "متأخرة"
                                            ? Colors.red[800]
                                            : task.status == "مازالت لم تبدأ"
                                            ? Colors.blue[800]
                                            : Colors.orange[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  );
                },
              ),
            )




          ],
        ),
        /******************/
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddDailyTaskModal(
                title: "إضافة مهمة جديدة لليوم",
                submitButtonText: "إضافة",
                // Supprime l'ajout direct dans dailyTasks, on recharge depuis Firestore
                // onAdd n'est plus nécessaire ici
              ),
            ).then((_) {
              // ✅ Recharge la liste après la fermeture du modal
              _loadDailyTasks();
            });
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          selectedType: widget.selectedType,

        ),
      ),
    );
  }

}


