
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/evaluation_technician_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_evaluation_technician.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';

class ProjectEvaluationTechnician extends StatefulWidget {
  final Project project;
  final String? ownerId;

  const ProjectEvaluationTechnician({super.key, required this.project, required this.ownerId});

  @override
  State<ProjectEvaluationTechnician> createState() => _ProjectEvaluationTechnicianState();
}

class _ProjectEvaluationTechnicianState extends State<ProjectEvaluationTechnician> {
  late final CreateNotificationUseCase _createNotificationUseCase;
  late final AddEvaluationTechnicianUseCase _addEvaluationTechnicianUseCase;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController employeeCtrl = TextEditingController();
  bool isSaving = false;
  String? engineerName;
  bool isLoading = true;
  List<Employees> employees = [];
  String? selectedEmployeeId;
  String? selectedEmployeeName;
  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _addEvaluationTechnicianUseCase = sl<AddEvaluationTechnicianUseCase>();
    engineerName = widget.project.engineerName;
    isLoading = false;
    _loadEmployees();
  }
  Future<void> _loadEmployees() async {
    final result = await sl<GetEmployeeUseCase>().call();
    result.fold( (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => employees = List<Employees>.from(list)), ); }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
                "📘تقييم الفنيين",
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
          const SizedBox(height: 20),

          ModernCard(
            title: "معلومات التصفية",
            icon: Icons.filter_list,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ModernCard(
            title: "ملاحظات حول الفنيين",
            icon: Icons.description,
            child: Column(
              children: [
                NewRoundTextField(
                  controller: _notesController,
                  hintText: "اكتب ملاحظاتك هنا...",
                  maxLines: 5,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  right: const Icon(Icons.description_outlined, color: Colors.grey),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      setState(() => isSaving = true);

                      final description = _notesController.text.trim();

                      if (description.isEmpty) {
                        CustomSnackBar.show(
                          context,
                          message: "الرجاء كتابة الملاحظات أولاً",
                          type: SnackBarType.warning,
                        );
                        setState(() => isSaving = false);
                        return;
                      }

                      if (selectedEmployeeId == null) {
                        CustomSnackBar.show(
                          context,
                          message: "الرجاء اختيار الفني أولاً",
                          type: SnackBarType.warning,
                        );
                        setState(() => isSaving = false);
                        return;
                      }

                      final evaluation = EvaluationTechnician(
                        idProject: widget.project.id,
                        idEngineer: widget.ownerId,
                        nameEngineer: engineerName,
                        description: description,
                        idEmployee: selectedEmployeeId,
                        nameEmployee: selectedEmployeeName,
                      );

                      final result = await _addEvaluationTechnicianUseCase.call(params: evaluation);

                      result.fold(
                            (error) {
                          CustomSnackBar.show(
                            context,
                            message: error,
                            type: SnackBarType.error,
                          );
                        },
                            (success) {
                          CustomSnackBar.show(
                            context,
                            message: "تم حفظ التقييم بنجاح ✅",
                            type: SnackBarType.success,
                          );

                          setState(() {
                            _notesController.clear();
                            employeeCtrl.clear();
                            selectedEmployeeId = null;
                            selectedEmployeeName = null;
                          });
                        },
                      );

                      setState(() => isSaving = false);
                    },                    style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                    child: isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "موافق",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),              ],
            ),
          ),
          const SizedBox(height: 18),
          /// Bouton موافق

        ],
      ),
    );
  }

}
class ModernCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const ModernCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          /// 🔥 Header
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔥 Content
          child,
        ],
      ),
    );
  }
}