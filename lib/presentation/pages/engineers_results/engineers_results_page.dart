import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/evaluation_engineer_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_evaluation_engineer.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';
import 'package:flutter/foundation.dart';



class EngineersResultsPage  extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const EngineersResultsPage({super.key, required this.selectedType,    required this.projectName
  });

  @override
  State<EngineersResultsPage> createState() => _EngineersResultsPageState();
}

class _EngineersResultsPageState extends State<EngineersResultsPage> {
  int _selectedIndex = 0;
  bool isLoading = true;
  List<Engineer> engineers = [];
  String? selectedEngineer;
  List<EvaluationEngineer> evaluations = [];
  late final CreateNotificationUseCase _createNotificationUseCase;
  final TextEditingController engineerCtrl = TextEditingController();
  Map<String, String> projectsMap = {};
  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadEngineers();
    _loadProjects();
  }
  Future<void> _loadProjects() async {
    final result = await sl<GetProjectUseCase>().call();

    result.fold(
          (error) => debugPrint("Error loading projects"),
          (list) {
        setState(() {
          projectsMap = {
            for (var p in list)  p.id.trim(): p.projectName?? ""
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
  String normalizeProjectId(String? id) {
    if (id == null) return '';
    return id.split('/').last.trim();
  }
  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold( (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)), ); }

  Future<void> loadEvaluations() async {
    final result = await sl<GetAllEvaluationEngineerUseCase>().call();

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
              .where((e) => e.nameEngineer == engineerCtrl.text)
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
              // 🔵 HEADER
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
                    "نتائج المهندسين",
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

              // ⭐ FILTER CARD
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

                        buildLabel("المهندس"),

                        NewRoundSelectField(
                          hintText: "اختيار المهندس",
                          options: engineers.map((e) => e.firstName ?? "").toList(),
                          controller: engineerCtrl,
                          rightIcon: const Icon(Icons.engineering),

                          onChanged: (value) async {
                            final eng = engineers.firstWhere(
                                  (e) => e.firstName == value,
                            );

                            selectedEngineer = eng.id;
                            await loadEvaluations();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ⭐ RESULTS TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: const Text(
                    "النتائج",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ⭐ RESULTS LIST
              evaluations.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "لا توجد نتائج",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
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
                            "الموقع ${index + 1}",
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
                            children: [
                              const Icon(Icons.engineering,
                                  size: 20, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                eval.nameEngineer ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.event_available,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        "النتيجة الإجمالية لعدد النقاط تُقيَّم لكل مهندس حسب كل مشروع",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  "${eval.steps?['final']?.score ?? 0}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            CustomSnackBar.show(
              context,
              message: "زر مخصص لإضافة محتوى جديد",
              type: SnackBarType.info,
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),

        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,

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

