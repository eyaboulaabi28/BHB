import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/settings_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_settings.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';

import '../../../service_locator.dart';

class AddSettingsModal extends StatefulWidget {
  final String title;
  final String submitButtonText;
  final Function(Map<String, String> values) onAdd;

  const AddSettingsModal({
    super.key,
    required this.title,
    required this.submitButtonText,
    required this.onAdd,
  });

  @override
  State<AddSettingsModal> createState() => _AddSettingsModalState();
}

class _AddSettingsModalState extends State<AddSettingsModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController totalCtrl = TextEditingController();
  final TextEditingController startCtrl = TextEditingController();
  final TextEditingController endCtrl = TextEditingController();
  final TextEditingController hourlyRateCtrl = TextEditingController();
  final TextEditingController employeeRankCtrl = TextEditingController();

  late final CreateNotificationUseCase _createNotificationUseCase;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
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

  void calculateHours() {
    if (startCtrl.text.isEmpty || endCtrl.text.isEmpty) return;

    try {
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
        final diffHours = diff / 60;
        totalCtrl.text = diffHours.toStringAsFixed(2);
      } else {
        totalCtrl.text = "";
      }
    } catch (e) {
      totalCtrl.text = "";
    }
  }

  String? validateTime(String? value) {
    if (value == null || value.isEmpty) return "الرجاء إدخال الوقت";

    final regex = RegExp(r'^\d{2}:\d{2}$');
    if (!regex.hasMatch(value)) return "الرجاء إدخال الوقت بصيغة HH:mm";

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 550,
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

                // ⭐ TITRE DU MODAL
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                NewRoundTextField(
                  hintText: "عدد ساعات العمل",
                  controller: totalCtrl,
                  right: const Icon(Icons.timer, color: Colors.grey),
                ),

                const SizedBox(height: 15),

                NewRoundTextField(
                  hintText: "ساعة الانطلاق في العمل",
                  controller: startCtrl,
                  validator: validateTime,
                  right: const Icon(Icons.access_time, color: Colors.grey),
                  onChanged: (_) => calculateHours(),
                ),

                const SizedBox(height: 15),

                NewRoundTextField(
                  hintText: "ساعة نهاية العمل",
                  controller: endCtrl,
                  validator: validateTime,
                  right: const Icon(Icons.access_time, color: Colors.grey),
                  onChanged: (_) => calculateHours(),
                ),

                const SizedBox(height: 15),

                NewRoundSelectField(
                  hintText: "رتبة الموظف",
                  options: [
                    "فني كهرباء", "فني سباكة", "عامل", "مساعد",
                    "فني", "مهندس", "مدير النظام"
                  ],
                  controller: employeeRankCtrl,
                  validator: (v) => v == null ? "الرجاء اختيار الرتبة" : null,
                  rightIcon: const Icon(Icons.category, color: Colors.grey),
                ),

                const SizedBox(height: 15),

                NewRoundTextField(
                  hintText: "سعر الساعة",
                  controller: hourlyRateCtrl,
                  keyboardType: TextInputType.number,
                  right: const Icon(Icons.monetization_on, color: Colors.grey),
                  validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال سعر الساعة" : null,
                ),

                const SizedBox(height: 20),

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
                    // Bouton Valider
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final settings = SettingsModel(
                              workHoursCount: totalCtrl.text,
                              workStartTime: startCtrl.text,
                              workEndTime: endCtrl.text,
                              hourlyRate: hourlyRateCtrl.text,
                              employeeRank: employeeRankCtrl.text,
                            );

                            final result =
                            await sl<AddSettingsUseCase>().call(params: settings);

                            result.fold(
                                  (error) {
                                CustomSnackBar.show(
                                  context,
                                  message: "خطأ: $error",
                                  type: SnackBarType.error,
                                );
                              },
                                  (_) async {
                                CustomSnackBar.show(
                                  context,
                                  message: "تم حفظ الإعدادات بنجاح",
                                  type: SnackBarType.success,
                                );

                                await _sendNotification(
                                  title: "إضافة إعدادات جديدة",
                                  message:
                                  "تم تحديث إعدادات رتبة الموظف: ${settings.employeeRank}",
                                  route: "/home",
                                );

                                widget.onAdd({
                                  "workHoursCount": settings.workHoursCount ?? "",
                                  "workStartTime": settings.workStartTime ?? "",
                                  "workEndTime": settings.workEndTime ?? "",
                                  "hourlyRate": settings.hourlyRate ?? "",
                                  "employeeRank": settings.employeeRank ?? "",
                                });

                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
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

              ],
            ),
          ),
        ),
      ),
    );
  }
}


