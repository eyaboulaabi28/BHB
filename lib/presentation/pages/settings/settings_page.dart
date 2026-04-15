import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/attendance_time_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/settings_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance_time.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_settings.dart';
import 'package:app_bhb/presentation/pages/attendance/add_attendance_modal.dart';
import 'package:app_bhb/presentation/pages/attendance/edit_work_hours_modal.dart';
import 'package:app_bhb/presentation/pages/employees/add_employee_modal.dart';
import 'package:app_bhb/presentation/pages/settings/add_settings_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal;
import '../../../service_locator.dart';


class SettingsPage extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const SettingsPage({super.key, required this.selectedType, required this.projectName});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;
  late final GetSettingsUseCase _getAllSettingsUseCase;
  late final DeleteSettingsUseCase _deleteSettingsUseCase;
  late final NotificationService _notificationService;
  final TextEditingController startTimeCtrl = TextEditingController();
  final TextEditingController endTimeCtrl = TextEditingController();
  bool isAdmin = true;
  List<SettingsModel> settings = [];
  String? attendanceTimeId;
  String? startTimeError;
  String? endTimeError;
  @override

  void initState() {
    super.initState();
    _getAllSettingsUseCase = sl<GetSettingsUseCase>();
    _deleteSettingsUseCase = sl<DeleteSettingsUseCase>();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());

    _fetchSettings();
     _loadAttendanceTime();
  }

  bool isValidTime(String value) {
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return regex.hasMatch(value);
  }

  Future<void> _loadAttendanceTime() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('AttendanceTime')
          .orderBy('createdAt', descending: true) // ⭐ IMPORTANT
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;

        attendanceTimeId = doc.id;

        final data = doc.data();

        final start = DateTime.parse(data['startTime']);
        final end = DateTime.parse(data['endTime']);

        setState(() {
          startTimeCtrl.text =
          "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";

          endTimeCtrl.text =
          "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
        });
      } else {
        setState(() {
          startTimeCtrl.text = "06:30";
          endTimeCtrl.text = "16:30";
        });
      }
    } catch (e) {
      debugPrint("Error loading attendance time: $e");
    }
  }
  Future<void> _fetchSettings() async {
    final result = await _getAllSettingsUseCase.call();
    result.fold(
          (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $failure")),



        );
      },
          (settingsList) {
        setState(() {
          settings = List<SettingsModel>.from(settingsList);
        });
      },
    );
  }
  Future<void> _deleteSetting(String settingsId) async {
    final result = await _deleteSettingsUseCase.call(params: settingsId);
    final deleted =
    settings.firstWhere((e) => e.id == settingsId, orElse: () => SettingsModel());

    result.fold(
          (failure) {
        CustomSnackBar.show(context, message: "خطأ  في الحذف  : $failure", type: SnackBarType.error);
      },
          (_) async {
        setState(() {
          settings.removeWhere((e) => e.id == settingsId);
        });

        CustomSnackBar.show(context, message: "تم حذف الإعدادات بنجاح", type: SnackBarType.success);

        // ✅ Notification
        await _notificationService.send(
          title: "حذف إعدادات",
          message: "تم حذف إعدادات رتبة الموظف: ${deleted.employeeRank ?? ""}",
          route: "/settings",
        );
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
                  "الإعدادات العامة",
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "أوقات الدوام",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔹 Start Time
                      const Text("بداية الدوام",
                          style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),


                      const SizedBox(height: 5),
                      NewRoundTextField(
                        hintText: "08:30",
                        controller: startTimeCtrl,
                        right: const Icon(Icons.login),
                      ),
                      const SizedBox(height: 5),

                      if (startTimeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            startTimeError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),

                      const SizedBox(height: 15),

                      const Text("نهاية الدوام",
                          style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
                      const SizedBox(height: 5),
                      NewRoundTextField(
                        hintText: "16:30",
                        controller: endTimeCtrl,
                        right: const Icon(Icons.logout),
                      ),

                      const SizedBox(height: 5),

                      if (endTimeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            endTimeError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),

                      const SizedBox(height: 15),

                      // 🔹 Button modify
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () async {
                            setState(() {
                              startTimeError = null;
                              endTimeError = null;
                            });

                            final start = startTimeCtrl.text.trim();
                            final end = endTimeCtrl.text.trim();

                            bool hasError = false;

                            if (!isValidTime(start)) {
                              startTimeError =
                              "الوقت يجب أن يكون بالشكل HH:MM الرجاء إدخال الوقت بصيغة صحيحة (مثال: 08:30)";
                              hasError = true;
                            }

                            if (!isValidTime(end)) {
                              endTimeError =
                              "الوقت يجب أن يكون بالشكل HH:MM الرجاء إدخال الوقت بصيغة صحيحة (مثال: 16:30)";
                              hasError = true;
                            }

                            if (hasError) {
                              setState(() {});
                              return;
                            }

                            /// ✅ تحويل النص إلى DateTime
                            try {
                              final startParts = start.split(":");
                              final endParts = end.split(":");

                              final now = DateTime.now();

                              final startTime = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                int.parse(startParts[0]),
                                int.parse(startParts[1]),
                              );

                              final endTime = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                int.parse(endParts[0]),
                                int.parse(endParts[1]),
                              );

                              final attendance = AttendanceTime(
                                startTime: startTime,
                                endTime: endTime,
                              );

                              /// 🔹 CAS 1: CREATE (أول مرة)
                              if (attendanceTimeId == null) {
                                final doc = FirebaseFirestore.instance
                                    .collection('AttendanceTime')
                                    .doc();

                                await doc.set({
                                  ...attendance.toMap(),
                                  "createdAt": FieldValue.serverTimestamp(), // ⭐ مهم
                                });

                                attendanceTimeId = doc.id;

                                CustomSnackBar.show(
                                  context,
                                  message: "تم إضافة وقت الدوام",
                                  type: SnackBarType.success,
                                );
                              }

                              /// 🔹 CAS 2: UPDATE
                              else {
                                await FirebaseFirestore.instance
                                    .collection('AttendanceTime')
                                    .doc(attendanceTimeId)
                                    .update({
                                  ...attendance.toMap(),
                                  "createdAt": FieldValue.serverTimestamp(), // ⭐ باش يبقى latest
                                });

                                CustomSnackBar.show(
                                  context,
                                  message: "تم تعديل وقت الدوام",
                                  type: SnackBarType.success,
                                );
                              }

                              /// 🔥 إعادة تحميل آخر قيمة (باش تتأكد UI يتحدث)
                              await _loadAttendanceTime();

                            } catch (e) {
                              CustomSnackBar.show(
                                context,
                                message: "خطأ في معالجة الوقت",
                                type: SnackBarType.error,
                              );
                            }
                          },
                          child: const Text(
                            "تعديل",
                            style: TextStyle(fontFamily: 'Tajawal'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: settings.isEmpty
                  ? const Center(
                child: Text(
                  "لا توجد إعدادات مضافة",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: settings.length,
                itemBuilder: (context, index) {
                  final item = settings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: TColor.secondary.withOpacity(0.2),
                            child: Icon(Icons.settings, color: TColor.primary),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.employeeRank ?? "",
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "سعر الساعة: ${item.hourlyRate ?? ""} | ساعات العمل: ${item.workHoursCount ?? ""}",
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),

                              ],
                            ),
                          ),
                          Row(
                            children: [

                              IconButton(
                                onPressed: () async {
                                  final confirm = await CustomDialog.show(
                                    context,
                                    title: "تأكيد الحذف",
                                    message: "هل أنت متأكد أنك تريد حذف هذا الإعداد؟",
                                    type: DialogType.confirm,
                                    confirmText: "حذف",
                                    cancelText: "إلغاء",
                                  );
                                  if (confirm == true && item.id != null) {
                                    await _deleteSetting(item.id!);
                                  }
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ],

                      ),
                    ),

                  );

                },
              ),
            ),

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
              builder: (context) => AddSettingsModal(
                title: "إضافة إعدادات",
                submitButtonText: "إضافة",
                onAdd: (values) {
                  setState(() {
                    settings.add(
                      SettingsModel(
                        workHoursCount: values["workHoursCount"] ?? "",
                        workStartTime: values["workStartTime"] ?? "",
                        workEndTime: values["workEndTime"] ?? "",
                        hourlyRate: values["hourlyRate"] ?? "",
                        employeeRank: values["employeeRank"] ?? "",
                      ),
                    );
                  });
                },
              ),
            ).then((_) {
              setState(() {}); // Rafraîchir après fermeture du modal
            });
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


