import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/data/auth/models/date_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_daily_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_date.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/daily_tasks/add_daily_task_modal.dart';
import 'package:app_bhb/presentation/pages/dates/add_date_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import '../../../service_locator.dart';


class DatesPage extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const DatesPage({super.key, required this.selectedType,    required this.projectName
  });

  @override
  State<DatesPage> createState() => _DatesPageState();
}

class _DatesPageState extends State<DatesPage> {
  int _selectedIndex = 0;
  List<Date> date = [];
  late final GetDateUseCase _getAllDateUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;
  late String? currentUserId;

  String _statusText(DateStatus status) {
    switch (status) {
      case DateStatus.pending:
        return "قيد الانتظار";
        case DateStatus.completed:
        return "منجز";
      case DateStatus.late:
        return "متأخر";
    }
  }
  DateStatus _statusFromText(String text) {
    switch (text) {
      case "متأخر":
        return DateStatus.late;
      default:
        return DateStatus.pending;
    }
  }
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAllDateUseCase = sl<GetDateUseCase>();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchDates();
  }
  Future<void> _reloadDates() async {
    setState(() => isLoading = true);
    await _fetchDates();
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

    await _createNotificationUseCase.call(notification: notif);
  }

  Future<void> _fetchDates() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userProfile =
    await sl<AuthFirebaseService>().getUserProfile(uid);

    userProfile.fold(
          (err) {
        CustomSnackBar.show(
          context,
          message: "خطأ في جلب المستخدم",
          type: SnackBarType.error,
        );
      },
          (data) async {
        final role = data['role'];

        final result = await _getAllDateUseCase.call(
          userId: uid,
          role: role,
        );

        result.fold(
              (_) {
            CustomSnackBar.show(
              context,
              message: "خطأ أثناء جلب المواعيد",
              type: SnackBarType.error,
            );
          },
              (list) {
            setState(() {
              date = List<Date>.from(list);
              isLoading = false;
            });
          },
        );
      },
    );
  }


  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  DateStatus _calculateStatus(Date d) {
    if (d.createdAt == null) return DateStatus.pending;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dateOnly = DateTime(
      d.createdAt!.year,
      d.createdAt!.month,
      d.createdAt!.day,
    );

    final diff = today.difference(dateOnly).inDays;

    if (diff >= 1) {
      return DateStatus.late;
    }

    return DateStatus.pending;
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
                  "إدارة المواعيد",
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
                  : date.isEmpty
                  ? const Center(
                child: Text(
                  "لا توجد مواعيد",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: date.length,
                itemBuilder: (context, index) {
                  final d = date[index];

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
                          // 🔵 Avatar
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                            TColor.secondary.withOpacity(0.2),
                            child: Icon(
                              Icons.event,
                              color: TColor.primary,
                            ),
                          ),
                          const SizedBox(width: 15),

                          // 📄 Infos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.customerName ?? "بدون اسم",
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const SizedBox(height: 5),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.build,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      d.typeDate ?? "",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),

                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatDate(d.createdAt),
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),


                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    _statusBadge(d.status),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              final pageContext = context;

                              // Controllers
                              final dateController = TextEditingController(
                                text: _formatDate(d.createdAt),
                              );
                              final typeController = TextEditingController(
                                text: d.typeDate ?? "",
                              );
                              DateTime selectedDate = d.createdAt ?? DateTime.now();
                              DateStatus selectedStatus = d.status;

                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              "تعديل الموعد",
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            /// 📅 Date picker
                                            NewRoundTextField(
                                              hintText: "تاريخ الموعد",
                                              controller: dateController,
                                              readOnly: true,
                                              right: const Icon(Icons.date_range),
                                              onTap: () async {
                                                final picked = await showDatePicker(
                                                  context: context,
                                                  initialDate: selectedDate,
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2100),
                                                  locale: const Locale('ar'),
                                                );

                                                if (picked != null) {
                                                  setModalState(() {
                                                    selectedDate = picked;
                                                    dateController.text = _formatDate(picked);
                                                  });
                                                }
                                              },
                                            ),

                                            const SizedBox(height: 15),
                                            NewRoundSelectField(
                                              hintText: "نوع الموعد",
                                              controller: typeController,
                                              options: const [
                                                "كهرباء",
                                                "سباكة",
                                              ],
                                              onChanged: (value) {
                                                typeController.text = value ?? "";
                                              },
                                            ),
                                            const SizedBox(height: 15),

                                            /// 🟢 Status select (NewRoundSelectField)
                                            NewRoundSelectField(
                                              hintText: "حالة الموعد",
                                              options: DateStatus.values
                                                  .map((e) => _statusText(e))
                                                  .toList(),
                                              controller: TextEditingController(
                                                text: _statusText(selectedStatus),
                                              ),
                                              onChanged: (value) {
                                                setModalState(() {
                                                  selectedStatus = _statusFromText(value!);
                                                });
                                              },
                                            ),

                                            const SizedBox(height: 25),

                                            /// 💾 Save
                                            Row(
                                              children: [


                                                /// 💾 Save
                                                Expanded(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: TColor.primary,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                    ),
                                                    onPressed: () async {
                                                      final updatedDate = Date(
                                                        id: d.id,
                                                        customerName: d.customerName,
                                                        uidCustomer: d.uidCustomer,
                                                        createdAt: selectedDate,
                                                        status: selectedStatus,
                                                        typeDate: typeController.text.trim(),

                                                      );

                                                      final result = await sl<UpdateDateUseCase>().call(
                                                        params: {
                                                          "id": updatedDate.id!,
                                                          "date": updatedDate,
                                                        },
                                                      );

                                                      result.fold(
                                                            (failure) {
                                                          CustomSnackBar.show(
                                                            pageContext,
                                                            message: "خطأ أثناء التحديث",
                                                            type: SnackBarType.error,
                                                          );
                                                        },
                                                            (_) {
                                                          setState(() {
                                                            final index = date.indexWhere((e) => e.id == d.id);
                                                            if (index != -1) {
                                                              date[index] = updatedDate;
                                                            }
                                                          });

                                                          CustomSnackBar.show(
                                                            pageContext,
                                                            message: "تم تحديث الموعد بنجاح",
                                                            type: SnackBarType.success,
                                                          );
                                                           _sendNotification(
                                                          title: "تعديل موعد",
                                                          message: "تم تعديل موعد العميل: ${updatedDate.customerName}",
                                                          route: "/home",
                                                          userId: currentUserId,
                                                          );

                                                          Navigator.pop(context);
                                                        },
                                                      );
                                                    },
                                                    child: const Text(
                                                      "حفظ",
                                                      style: TextStyle(
                                                        fontFamily: 'Tajawal',
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 15),

                                                /// ❌ Cancel
                                                Expanded(
                                                  child: OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      side: BorderSide(color: TColor.secondary),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
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

                                              ],
                                            ),


                                            const SizedBox(height: 15),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
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
              isDismissible: false,
              enableDrag: false,
              backgroundColor: Colors.transparent,
              builder: (context) => AddDateModal(
                title: "إضافة موعد جديد",
                submitButtonText: "إضافة",
                onAdd: (values) {
                  setState(() {
                    date.add(
                      Date(
                        uidCustomer: values["uidCustomer"] ,
                        customerName: values["customerName"] ,
                        createdAt : values["createdAt"] ,
                        typeDate : values["typeDate"] ,
                      ),
                    );
                    _reloadDates();
                  });
                },
              ),
            );
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
  Widget _statusBadge(DateStatus status) {
    Color color;
    String text;

    switch (status) {
      case DateStatus.pending:
        color = Colors.amber;
        text = "قيد الانتظار";
        break;
      case DateStatus.completed:
        color = Colors.green;
        text = "منتهي";
        break;
      case DateStatus.late:
        color = Colors.deepOrange;
        text = "متأخر";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

}


