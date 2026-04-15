import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/evaluation_engineer_model.dart';
import 'package:app_bhb/data/auth/models/evaluation_technician_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:app_bhb/data/auth/source/newSite_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_evaluation_engineer.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_evaluation_technician.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/new_site/NewSiteProjectDetailsPage.dart';
import 'package:app_bhb/presentation/pages/new_site/addSite_tasks_modal.dart';
import 'package:app_bhb/presentation/pages/new_site/newsite_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:printing/printing.dart';
import '../../../service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_newsite.dart';
import 'package:app_bhb/presentation/pages/new_site/add_newsite_modal.dart';


class TechnicianResultsPage  extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const TechnicianResultsPage({super.key, required this.selectedType,    required this.projectName
  });

  @override
  State<TechnicianResultsPage> createState() => _TechnicianResultsPageState();
}

class _TechnicianResultsPageState extends State<TechnicianResultsPage> {
  int _selectedIndex = 0;
  bool isLoading = true;
  List<EvaluationTechnician> evaluations = [];
  late final CreateNotificationUseCase _createNotificationUseCase;
  final TextEditingController employeeCtrl = TextEditingController();
  Map<String, String> projectsMap = {};
  List<Employees> employees = [];
  String? selectedEmployeeId;
  String? selectedEmployeeName;
  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadEmployees();
    _loadProjects();
  }

  String normalizeProjectId(String? id) {
    if (id == null) return '';
    return id.split('/').last.trim();
  }
  Future<void> _loadProjects() async {
    final result = await sl<GetProjectUseCase>().call();

    result.fold(
          (error) => debugPrint("Error loading projects"),
          (list) {
        setState(() {
          projectsMap = {
            for (var p in list)  p.id.trim(): p.projectName ?? ""
          };
        });
      },
    );
  }
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadEmployees() async {
    final result = await sl<GetEmployeeUseCase>().call();
    result.fold( (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => employees = List<Employees>.from(list)), ); }

  Future<void> loadEvaluations() async {
    final result = await sl<GetAllEvaluationTechnicianUseCase>().call();

    result.fold(
          (error) {
        CustomSnackBar.show(
          context,
          message: "Erreur loading evaluations",
          type: SnackBarType.error,
        );
      },
          (list) {
        setState(() {
          evaluations = list
              .where((e) => e.idEmployee == selectedEmployeeId) // ✅ الحل هنا
              .toList();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF2F4F3),
        appBar: AppBar(
          backgroundColor: TColor.primary,
          elevation: 0,
          title: const SizedBox(),
        ),
        body: SingleChildScrollView(
          child: Column(
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
                    "نتائج الفنيين",
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
              // CARD 1: FILTRES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "معلومات التصفية",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        buildLabel("الفني"),
                        NewRoundSelectField(
                          hintText: "اختيار الفني",
                          options: employees.map((e) => e.firstName ?? "").toList(),
                          controller: employeeCtrl,
                          rightIcon: const Icon(Icons.engineering),
                          onChanged: (value) {
                            final emp = employees.firstWhere(
                                  (e) => e.firstName == value,
                            );

                            setState(() {
                              selectedEmployeeId = emp.id;
                              selectedEmployeeName = emp.firstName;
                            });

                            loadEvaluations(); // 🔥 مهم جدا
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // CARD 2: RESULTATS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "النتائج",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    evaluations.isEmpty
                        ? const Text(
                      "لا توجد نتائج",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    )
                        : Column(
                      children: evaluations.asMap().entries.map((entry) {
                        int index = entry.key;
                        final eval = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "النتيجة ${index + 1}",
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.precision_manufacturing,
                                      size: 20, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    "المشروع: ${projectsMap[normalizeProjectId(eval.idProject)] ?? 'غير معروف'}",
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Icon(Icons.engineering, size: 20, color: Colors.blueAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    "المهندس: ${eval.nameEngineer ?? ''}",
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                       fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.redAccent.withOpacity(0.85),
                                      Colors.redAccent.withOpacity(0.6)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.description_outlined, color: Colors.white, size: 26),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "الملاحظات المتعلقة بالفنيين في هذا الموقع",
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 16,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          eval.description ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        /******************/
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            CustomSnackBar.show(context,
                message: "زر مخصص لإضافة محتوى جديد",
                type: SnackBarType.info);
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          selectedType: widget.selectedType,
          projectName: widget.projectName,
        ),
      ),
    );
  }


}

