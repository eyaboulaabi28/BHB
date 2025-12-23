import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_daily_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';

import '../../../service_locator.dart';

class AddDailyTaskModal extends StatefulWidget {
  final String title;
  final String submitButtonText;

  const AddDailyTaskModal({
    super.key,
    required this.title,
    required this.submitButtonText,
  });

  @override
  State<AddDailyTaskModal> createState() => _AddDailyTaskModalState();
}

class _AddDailyTaskModalState extends State<AddDailyTaskModal> {
  final _formKey = GlobalKey<FormState>();
   // Data
   List<Engineer> engineers = [];
   List<Project> projects = [];

  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController engineerCtrl = TextEditingController();
  final TextEditingController projectCtrl = TextEditingController();
  final TextEditingController statusCtrl = TextEditingController();
  final TextEditingController durationCtrl = TextEditingController();
  late final CreateNotificationUseCase _createNotificationUseCase;

  // ⬇️ EXACTEMENT LA MÊME FONCTION que AddProjectModal
  Future<void> _selectVacationDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      locale: const Locale("ar", "SA"),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context),
            child: child!,
          ),
        );
      },
      useRootNavigator: true,
    );

    if (pickedDate != null) {
      controller.text =
      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
    }
  }

  Widget _buildInput(
      {required IconData icon,
        required String hint,
        required TextEditingController controller,
        bool isDate = false,
        String? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NewRoundTextField(
        hintText: hint,
        controller: controller,
        obscureText: false,
        validator: validator != null ? (v) => v!.isEmpty ? validator : null : null,
        right: isDate
            ? GestureDetector(
          onTap: () => _selectVacationDate(controller),
          child: const Icon(Icons.calendar_today, color: Colors.grey),
        )
            : Icon(icon, color: Colors.grey),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _loadEngineers();
    _loadProjects();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
  }

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();

    if (!mounted) return;

    result.fold(
          (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)),
    );
  }

  Future<void> _loadProjects() async {
    final result = await sl<GetProjectUseCase>().call();

    if (!mounted) return; // ⬅️ éviter le crash

    result.fold(
          (error) => debugPrint("Error loading projects"),
          (list) => setState(() => projects = List<Project>.from(list)),
    );
  }

  DateTime? parseDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String message,
    String? userId,
    String? route,
  }) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      userId: userId,
      route: route,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _createNotificationUseCase(notification: notif);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 650,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                // Engineer
                NewRoundSelectField(
                  hintText: "اختار المهندس",
                  options: engineers.map((e) => e.firstName ?? "").toList(),
                  controller: engineerCtrl,
                  rightIcon: const Icon(Icons.engineering, color: Colors.grey),
                  validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار المهندس" : null,
                ),
                const SizedBox(height: 10),

                // Project
                NewRoundSelectField(
                  hintText: "اختار المشروع",
                  options: projects.map((p) => p.projectName ?? "").toList(),
                  controller: projectCtrl,
                  rightIcon: const Icon(Icons.apartment, color: Colors.grey),
                  validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار المشروع" : null,
                ),
                const SizedBox(height: 10),

                // Title
                NewRoundTextField(
                  hintText: "عنوان المهمة",
                  controller: titleCtrl,
                  right: const Icon(Icons.title, color: Colors.grey),
                  validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال العنوان" : null,
                ),
                const SizedBox(height: 10),

                // Description
                NewRoundTextField(
                  hintText: "تفاصيل المهمة",
                  controller: descCtrl,
                  maxLines: 4,
                  isPadding: true,
                  right: const Icon(Icons.description, color: Colors.grey),
                  validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال التفاصيل" : null,
                ),
                const SizedBox(height: 10),

                _buildInput(
                  icon: Icons.calendar_today,
                  hint: "تاريخ المهمة",
                  controller: dateCtrl,
                  isDate: true,
                ),
                //const SizedBox(height: 5),

                NewRoundTextField(
                  hintText: "المدة التقديرية للمهمة (بالأيام)",
                  controller: durationCtrl,
                  isPadding: true,
                  right: const Icon(Icons.timer, color: Colors.grey),
                  validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال المدة" : null,
                ),
                const SizedBox(height: 5),

                // Status
                NewRoundSelectField(
                  hintText: "حالة المهمة",
                  options: const [
                    "قيد الإنجاز",
                    "مكتملة",
                    "متأخرة", "مازالت لم تبدأ",
                  ],
                  controller: statusCtrl,
                  rightIcon: const Icon(Icons.flag, color: Colors.grey),
                  validator: (v) => (v == null || v.isEmpty) ? "الرجاء تحديد الحالة" : null,
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔹 Bouton إلغاء
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: TColor.secondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          "إلغاء",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TColor.secondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final selectedEngineer = engineers.firstWhere(
                                  (e) => e.firstName == engineerCtrl.text,
                              orElse: () => Engineer(id: null, firstName: engineerCtrl.text),
                            );
                            final selectedProject = projects.firstWhere(
                                  (p) => p.projectName == projectCtrl.text,
                              orElse: () => Project(id: null, projectName: projectCtrl.text),
                            );
                            final newDailyTask = DailyTasks(
                              engineerId: selectedEngineer.id,
                              projectId: selectedProject.id,
                              titleTask: titleCtrl.text,
                              description: descCtrl.text,
                              status: statusCtrl.text,
                              duration: durationCtrl.text,
                              createdAt: parseDate(dateCtrl.text.trim()),

                            );

                            // Appel du UseCase
                            final result = await sl<AddDailyTasksUseCase>().call(params: newDailyTask);

                            result.fold(
                                  (error) => CustomSnackBar.show(
                                context,
                                message: "حدث خطأ أثناء إضافة المهمة: $error",
                                type: SnackBarType.error,
                              ),
                                  (task) async {
                                // 🟢 D’abord afficher le snackbar
                                CustomSnackBar.show(
                                  context,
                                  message: "تمت إضافة المهمة بنجاح",
                                  type: SnackBarType.success,
                                );
                                await _sendNotification(
                                  title: "مهمة جديدة",
                                  message: "تم إسناد مهمة جديدة إليك: ${titleCtrl.text}",
                                  userId: selectedEngineer.id,
                                  route: "/home",
                                );
                                // 🟢 Attendre un peu pour laisser la liste parent se rafraîchir
                                await Future.delayed(const Duration(milliseconds:5));

                                if (!mounted) return;
                                Navigator.pop(context); // 🟢 Maintenant on ferme le modal

                              },
                            );

                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        ),
                        child: Text(
                          widget.submitButtonText,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
