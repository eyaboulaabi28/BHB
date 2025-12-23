import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/settings_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_settings.dart';
import 'package:app_bhb/presentation/pages/employees/add_employee_modal.dart';
import 'package:app_bhb/presentation/pages/settings/add_settings_modal.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal;
import '../../../service_locator.dart';


class SettingsPage extends StatefulWidget {
  final String selectedType;

  const SettingsPage({super.key, required this.selectedType});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;
  late final GetSettingsUseCase _getAllSettingsUseCase;
  late final DeleteSettingsUseCase _deleteSettingsUseCase;
  late final NotificationService _notificationService;

  List<SettingsModel> settings = [];

  @override
  void initState() {
    super.initState();
    _getAllSettingsUseCase = sl<GetSettingsUseCase>();
    _deleteSettingsUseCase = sl<DeleteSettingsUseCase>();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());
    _fetchSettings();
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

        ),
      ),
    );
  }
}


