import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/data/auth/models/check_in.dart';
import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_check_in.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_daily_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';

import '../../../service_locator.dart';

class AddDailyCheckInModal extends StatefulWidget {
  final String title;
  final String submitButtonText;
  final DailyCheckIn? existingData;

  const AddDailyCheckInModal({
    super.key,
    required this.title,
    required this.submitButtonText,
    this.existingData,

  });

  @override
  State<AddDailyCheckInModal> createState() => _AddDailyCheckInModalState();
}

class _AddDailyCheckInModalState extends State<AddDailyCheckInModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController engineerCtrl = TextEditingController();
  final TextEditingController dailyTasksCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController startCtrl = TextEditingController();
  final TextEditingController endCtrl = TextEditingController();
  final TextEditingController totalCtrl = TextEditingController();
  final TextEditingController numberDayCtrl = TextEditingController();
  final TextEditingController statusCtrl = TextEditingController();
  late final GetDailyTasksByEngineerIdStatusUseCase _getDailyTasksByEngineerIdStatusUseCase;
  late final UpdateDailyTasksStatusUseCase _updateDailyTasksStatusUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;

  bool presence = true;
  double oldHoursTotal = 0;
  int oldNumberDay = 0;
  // Exemple de liste d'ingénieurs pour sélection
  List<Engineer> engineers = [];
  List<DailyTasks> dailyTasks = [];

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold( (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)), ); }
  Future<void> _loadDailyTasks() async {
    final result =  await sl<GetDailyTasksByStatusUseCase>().call("مازالت لم تبدأ");
    result.fold( (error) => debugPrint("Error loading DailyTasks"),
          (list) => setState(() => dailyTasks = List<DailyTasks>.from(list)), ); }
  @override
  void initState() {
    super.initState();
    _updateDailyTasksStatusUseCase = sl<UpdateDailyTasksStatusUseCase>();
    _getDailyTasksByEngineerIdStatusUseCase = sl<GetDailyTasksByEngineerIdStatusUseCase>();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadEngineers();
    _loadDailyTasks();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.existingData != null) {
        final data = widget.existingData!;

        // ⚠️ ID et texte corrects
        selectedEngineerId = data.engineerId;
        selectedTaskId = data.tasks ?? "";

        startCtrl.text = data.hoursStart ?? "";
        endCtrl.text = data.hoursEnd ?? "";
        totalCtrl.text = data.hoursTotal ?? "";
        numberDayCtrl.text = data.numberDay ?? "";
        statusCtrl.text = data.status ?? "";
        dateCtrl.text = data.createdAt != null
            ? "${data.createdAt!.day}/${data.createdAt!.month}/${data.createdAt!.year}"
            : "";
        presence = (data.presence == "حاضر");

        await _loadEngineers();
        await _loadDailyTasks();
        if (!engineers.any((e) => e.id == data.engineerId)) {
          engineers.add(Engineer(id: data.engineerId, firstName: "مهندس"));
        }
        if (!dailyTasks.any((t) => t.id == data.tasks)) {
          dailyTasks.add(DailyTasks(id: data.tasks, titleTask: "مهمة غير معروفة"));
        }
        engineerCtrl.text = engineers.firstWhere((e) => e.id == data.engineerId).firstName ?? "";
        dailyTasksCtrl.text = dailyTasks.firstWhere((t) => t.id == data.tasks).titleTask ?? "";
        oldHoursTotal = double.tryParse(widget.existingData!.hoursTotal ?? "0") ?? 0;
        oldNumberDay = int.tryParse(widget.existingData!.numberDay ?? "0") ?? 0;

        setState(() {});
      }
    });
  }
  void calculateHours() {
    if (startCtrl.text.isEmpty || endCtrl.text.isEmpty) return;

    try {
      // Format attendu: HH:mm (exemple: 08:30)
      final start = TimeOfDay(
        hour: int.parse(startCtrl.text.split(":")[0]),
        minute: int.parse(startCtrl.text.split(":")[1]),
      );

      final end = TimeOfDay(
        hour: int.parse(endCtrl.text.split(":")[0]),
        minute: int.parse(endCtrl.text.split(":")[1]),
      );

      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      final diff = endMinutes - startMinutes;

      if (diff > 0) {
        final hours = diff ~/ 60;
        final minutes = diff % 60;
        final diffHours = diff / 60;
        totalCtrl.text = diffHours.toStringAsFixed(2);
      } else {
        totalCtrl.text = "";
      }
    } catch (e) {
      totalCtrl.text = "";
    }
  }
  String? selectedEngineerId;
  String? selectedTaskId;

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
  String? validateTimeFormat(String? value) {
    if (value == null || value.isEmpty) {
      return "الرجاء إدخال الوقت";
    }

    final regex = RegExp(r'^\d{2}:\d{2}$');
    if (!regex.hasMatch(value)) return "الرجاء إدخال الوقت بصيغة HH:mm (مثال: 08:30)";

    final parts = value.split(":");
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return "وقت غير صالح";
    if (hour < 0 || hour > 23) return "الساعة يجب أن تكون بين 00 و 23";
    if (minute < 0 || minute > 59) return "الدقائق يجب أن تكون بين 00 و 59";

    return null;
  }

  Future<void> _sendNotification({
    required String title,
    required String message,
    String? route,
    String? userId,
  }) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      createdAt: DateTime.now(),
      userId: userId,
      route: route,
      isRead: false,
    );

    await _createNotificationUseCase(notification: notif);
  }
  Future<void> updateTaskStatus() async {
    final docId = selectedTaskId ?? widget.existingData?.tasks;
    debugPrint("💡 updateTaskStatus called with task ID: $docId");
    if (docId == null || docId.isEmpty) {
      debugPrint("⚠️ ID de la tâche est null ou vide !");
      return;
    }
    final task = dailyTasks.firstWhere(
          (t) => t.id == docId,
      orElse: () => DailyTasks(
        id: docId,
        titleTask: dailyTasksCtrl.text,
      ),
    );
    final updatedTask = DailyTasks(
      id: docId,
      titleTask: task.titleTask,
      status: statusCtrl.text,
    );
    final result = await _updateDailyTasksStatusUseCase(params: updatedTask);
    result.fold(
          (error) {
        CustomSnackBar.show(context,
            message: "خطأ في تحديث حالة المهمة: $error",
            type: SnackBarType.error);
      },
          (_) {
        CustomSnackBar.show(context,
            message: "تم تحديث حالة المهمة بنجاح",
            type: SnackBarType.success);
        _sendNotification(
          title: "تحديث حضور",
          message: "تم تحديث بيانات الحضور للمهندس",
          route: "/home",
          userId: selectedEngineerId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
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
                // Présence toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "الحضور اليومي",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: presence,
                      onChanged: (val) {
                        setState(() {
                          presence = val;
                          if (!presence) ;
                        });
                      },
                      activeColor: TColor.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.existingData == null) ...[
                  NewRoundSelectField(
                    hintText: "اختار المهندس",
                    options: engineers.map((e) => e.firstName ?? "").toList(),
                    controller: engineerCtrl,
                    rightIcon: const Icon(Icons.engineering, color: Colors.grey),
                    validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار المهندس" : null,
                    onChanged: (value) async {
                      // 1️⃣ Récupérer l'ingénieur sélectionné
                      final eng = engineers.firstWhere((e) => e.firstName == value);

                      // 2️⃣ Stocker l'ID
                      setState(() {
                        selectedEngineerId = eng.id;
                      });

                      // 3️⃣ Charger les tâches SI selectedEngineerId existe
                      if (selectedEngineerId != null) {
                        final result = await _getDailyTasksByEngineerIdStatusUseCase(
                          engineerId: selectedEngineerId!,   // ⬅️ ici la correction
                          status: "مازالت لم تبدأ",
                        );

                        result.fold(
                              (error) => CustomSnackBar.show(
                            context,
                            message: "خطأ في تحميل المهام: $error",
                            type: SnackBarType.error,
                          ),
                              (tasks) {
                            setState(() {
                              dailyTasks = tasks;
                              dailyTasksCtrl.text = ""; // reset le champ tâche
                            });
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  NewRoundSelectField(
                    onChanged: (value) {
                      final task = dailyTasks.firstWhere((t) => t.titleTask == value);
                      setState(() {
                        selectedTaskId = task.id;
                      });
                    },
                    hintText: dailyTasks.isEmpty ? "لا توجد مهام" : "اختار المهمة",
                    options: dailyTasks.isEmpty ? ["لا توجد مهام"] : dailyTasks.map((e) => e.titleTask ?? "").toList(),
                    controller: dailyTasksCtrl,
                    rightIcon: const Icon(Icons.title, color: Colors.grey),
                    validator: (v) {
                      if (dailyTasks.isEmpty) return "لا توجد مهام للاختيار";
                      return (v == null || v.isEmpty) ? "الرجاء اختيار المهمة" : null;
                    },
                    readOnly: dailyTasks.isEmpty,
                  ),
                  const SizedBox(height: 10),
                ],

                // Nombre d'heures travaillées
                NewRoundTextField(
                  hintText: "ساعة الانطلاق في العمل",
                  controller: startCtrl,
                  keyboardType: TextInputType.number,
                  validator: validateTimeFormat,
                  right: const Icon(Icons.access_time, color: Colors.grey),
                  onChanged: (_) => calculateHours(),

                ),
                const SizedBox(height: 10),

                NewRoundTextField(
                  hintText: "ساعة نهاية العمل",
                  controller: endCtrl,
                  keyboardType: TextInputType.number,
                  validator: validateTimeFormat,
                  right: const Icon(Icons.access_time, color: Colors.grey),
                  onChanged: (_) => calculateHours(),

                ),
                const SizedBox(height: 10),

                // Nombre d'heures travaillées
                NewRoundTextField(
                  hintText: "عدد ساعات العمل",
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  right: const Icon(Icons.access_time, color: Colors.grey),
                  readOnly: true,

                ),
                const SizedBox(height: 10),
                // Nombre d'heures travaillées
                NewRoundTextField(
                  hintText: "ايام العمل",
                  controller: numberDayCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty)? "الرجاء إدخال عدد الساعات": null,
                  right: const Icon(Icons.calendar_view_day, color: Colors.grey),
                ),
                const SizedBox(height: 10),

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
                _buildInput(
                  icon: Icons.calendar_today,
                  hint: "تاريخ ",
                  controller: dateCtrl,
                  isDate: true,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouton إلغاء
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
                          if (_formKey.currentState?.validate() ?? false) {

                            final newHoursTotal = double.tryParse(totalCtrl.text) ?? 0;
                            final newNumberDay = int.tryParse(numberDayCtrl.text) ?? 0;

                            final checkIn = DailyCheckIn(
                              id: widget.existingData?.id,
                              engineerId: selectedEngineerId ?? widget.existingData!.engineerId,
                              tasks: selectedTaskId ?? widget.existingData!.tasks,
                              presence: presence ? "حاضر" : "غائب",
                              hoursStart: startCtrl.text,
                              hoursEnd: endCtrl.text,
                              hoursTotal: (oldHoursTotal + newHoursTotal).toStringAsFixed(2),
                              status: statusCtrl.text,
                              numberDay: (oldNumberDay + newNumberDay).toString(),
                              createdAt: parseDate(dateCtrl.text.trim()),
                            );

                            if (widget.existingData != null) {
                              // 🔹 Edition
                              final result = await sl<UpdateDailyCheckInUseCase>().call(params: checkIn);
                              result.fold(
                                    (error) {
                                  CustomSnackBar.show(context, message: "فشل تحديث الحضور: $error", type: SnackBarType.error);
                                },
                                    (_) async {

                                  await updateTaskStatus(); // ✅ Mise à jour du statut de la tâche
                                  CustomSnackBar.show(context, message: "تم تحديث الحضور بنجاح", type: SnackBarType.success);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                              );
                            } else {
                              // 🔹 Ajout
                              final result = await sl<AddDailyCheckInUseCase>().call(params: checkIn);

                              result.fold(
                                    (error) {
                                  CustomSnackBar.show(context, message: "حدث خطأ أثناء إضافة الحضور: $error", type: SnackBarType.error);
                                },
                                    (_) async {
                                  await updateTaskStatus(); // ✅ Mise à jour du statut de la tâche
                                  CustomSnackBar.show(context, message: "تم تسجيل الحضور بنجاح", type: SnackBarType.success);
                                  await _sendNotification(
                                    title: "حضور جديد",
                                    message: "تم تسجيل حضور للمهندس بنجاح",
                                    route: "/home",  // يمكنك تغييره حسب مساراتك
                                    userId: selectedEngineerId,
                                  );
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                              );
                            }
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

  Widget _buildInput({required IconData icon, required String hint, required TextEditingController controller, bool isDate = false, String? validator}) {
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
}
