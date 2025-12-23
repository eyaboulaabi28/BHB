import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/employees/add_employee_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import '../../../service_locator.dart';

class ProjectEmployees extends StatefulWidget {
  final String projectId;

  const ProjectEmployees({super.key, required this.projectId});

  @override
  State<ProjectEmployees> createState() => _ProjectEmployeesState();
}


class _ProjectEmployeesState extends State<ProjectEmployees> {

  double? selectedLat;
  double? selectedLng;
  final List<Map<String, dynamic>> _projectEmployees = [];
  late final NotificationService _notificationService;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadProjectEmployees();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());
    _loadUserRole();
  }

  Future<void> _loadProjectEmployees() async {
    if (widget.projectId == null) return;

    final result = await sl<GetEmployeerByProjectIdUseCase>()
        .call(params: widget.projectId);

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "Erreur: $failure",
          type: SnackBarType.error,
        );
      },
          (employeeList) {
        setState(() {
          _projectEmployees.clear();
          _projectEmployees.addAll(
            (employeeList as List<Employees>).map((m) => {
              'projectId': m.projectId,
              'firstName': m.firstName,
              'profession': m.profession,
              'email': m.email,
              'phone': m.phone,
            }),
          );
        });
      },
    );
  }


  void _addProjectEmployee() async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return AddEmployeeModal(
            projectId: widget.projectId,
            onAdd: (values) async {
              try {
                if (values["firstName"] == null || values["email"] == null|| values["profession"] == null|| values["phone"] == null) {
                  throw Exception("بيانات غير مكتملة، يرجى تعبئة جميع الحقول");
                }
                setState(() {
                  _projectEmployees.add({
                    'projectId': widget.projectId,
                    'firstName': values["firstName"],
                    'email': values["email"],
                    'profession': values["profession"],
                    'phone': values["phone"],
                    "latitude": selectedLat,
                    "longitude": selectedLng,
                  });
                });
                CustomSnackBar.show(
                  context,
                  message: "تمت إضافة الموظف بنجاح ✅",
                  type: SnackBarType.success,
                );
                _notificationService.send(
                  title: "إضافة الموظف لمشروع",
                  message: "تم إضافة الموظف لمشروع: ${values["firstName"]}",
                  route: "/home",
                );
              } catch (e) {
                CustomSnackBar.show(
                  context,
                  message: "حدث خطأ أثناء إضافة الموظف: ${e.toString()}",
                  type: SnackBarType.error,
                );
              }
            },
          );
        },
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: "حدث خطأ غير متوقع: ${e.toString()}",
        type: SnackBarType.error,
      );
    }
  }


  Future<void> _loadUserRole() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final result = await sl<AuthFirebaseService>().getUserProfile(userId);

    result.fold(
          (err) => null,
          (data) {
        if (!mounted) return;
        setState(() {
          _userRole = (data['role'] as String?)?.toLowerCase();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📘 موظفي المشروع ",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_userRole != "customer")
                ElevatedButton.icon(
                onPressed: _addProjectEmployee,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text("إضافة موظف"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Si aucune matière
          if (_projectEmployees.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.timeline_outlined,
                      color: Colors.grey.shade400, size: 70),
                  const SizedBox(height: 8),
                  const Text(
                    "لم تتم إضافة أي موظفي بعد",
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),

          // Liste des matériaux
          ..._projectEmployees.asMap().entries.map((entry) {
            final index = entry.key;
            final employee = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.1),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 title: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: TColor.primary.withOpacity(0.2),
                      child:  Icon(Icons.people, color: TColor.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "الموظف ${index + 1} : ${employee['firstName']}",
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  if (employee['email'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "البريد الإلكتروني: ${employee['email']}",
                              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (employee['phone'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_outlined, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "الهاتف: ${employee['phone']}",
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  if (employee['profession'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.work_outline, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "المهنة: ${employee['profession']}",
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                ],

              ),
            );
          }).toList(),
        ],
      ),
    );
  }

}
