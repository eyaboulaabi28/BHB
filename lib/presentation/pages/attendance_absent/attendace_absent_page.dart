import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceAbsentPage extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const AttendanceAbsentPage({super.key, required this.selectedType,    required this.projectName
  });

  @override
  State<AttendanceAbsentPage> createState() => _AttendanceAbsentPageState();
}

class _AttendanceAbsentPageState extends State<AttendanceAbsentPage> {
  int _selectedIndex = 0;
  UserCreationReq user = UserCreationReq();
  late var _getAttendanceUseCase = sl<GetAttendanceUseCase>();
  List<Employees> employees = [];
  List<Employees> filteredEmployees = [];

  List<Attendance> absentAttendances = [];
  List<Attendance> filteredAbsentAttendances = [];

  final TextEditingController _searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  List<Attendance> attendances = [];

  @override
  void initState() {
    super.initState();
    _getAttendanceUseCase = sl<GetAttendanceUseCase>();
    _loadCurrentUserProfile();
    _loadAbsentAttendances();
    final now = DateTime.now();

    // Début du mois courant
    startDate = DateTime(now.year, now.month, 1);

    // Fin du mois courant
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // Si la fin du mois est dans le futur, prendre aujourd'hui
    endDate = endOfMonth.isAfter(now) ? now : endOfMonth;
  }

  Future _loadAbsentAttendances1() async {
    final result = await _getAttendanceUseCase.call();

    result.fold(
          (failure) {
        print(failure);
      },
          (data) {
        final attendances = data as List<Attendance>;

        final start = startDate != null
            ? DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
          0,
          0,
          0,
        )
            : null;

        final end = endDate != null
            ? DateTime(
          endDate!.year,
          endDate!.month,
          endDate!.day,
          23,
          59,
          59,
        )
            : null;

        final absents = attendances.where((attendance) {
          final status =
          attendance.status?.trim().toLowerCase();

          final reason =
          attendance.absenceReason?.trim();

          final isAbsent = status == "absent";

          final isAlreadyProcessed =
              reason == "غياب بدون عذر";

          bool isInRange = true;

          if (start != null &&
              end != null &&
              attendance.createdAt != null) {
            isInRange =
                attendance.createdAt!.isAfter(
                    start.subtract(const Duration(seconds: 1))) &&
                    attendance.createdAt!.isBefore(
                        end.add(const Duration(seconds: 1)));
          }

          return isAbsent &&
              !isAlreadyProcessed &&
              isInRange;
        }).toList();

        setState(() {
          absentAttendances = absents;
          filteredAbsentAttendances = absents;
        });
      },
    );
  }



  Future<void> _loadCurrentUserProfile() async {
    final fbUser = FirebaseAuth.instance.currentUser;

    if (fbUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(fbUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          user = UserCreationReq.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  void _filterEmployees(String value) {
    setState(() {
      filteredAbsentAttendances =
          absentAttendances.where((attendance) {
            final name =
                attendance.employeeName?.toLowerCase() ?? '';

            return name.contains(value.toLowerCase());
          }).toList();
    });
  }
  Future _loadAbsentAttendances() async {
    final result = await _getAttendanceUseCase.call();

    result.fold(
          (failure) {
        print("ERROR => $failure");
      },
          (data) {
        print("TOTAL ATTENDANCE = ${(data as List).length}");

        final attendances = data as List<Attendance>;

        for (final item in attendances) {
          print("${item.employeeName} | ${item.status} | ${item.absenceReason}");
        }

        /// 🔴 FILTER LOGIC UPDATED
        final absents = attendances.where((attendance) {
          final status = attendance.status?.trim().toLowerCase();

          final reason = attendance.absenceReason?.trim();

          /// 1. doit être absent
          final isAbsent = status == "absent";

          /// 2. exclure les déjà traités "بدون عذر"
          final isAlreadyProcessed =
              reason == "غياب بدون عذر";

          return isAbsent && !isAlreadyProcessed;
        }).toList();

        print("ABSENTS = ${absents.length}");

        setState(() {
          absentAttendances = absents;
          filteredAbsentAttendances = absents;
        });
      },
    );
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
                  "إدارة الغيابات",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(startDate != null
                      ? "من: ${startDate!.year}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}"
                      : "اختر تاريخ البداية"),
                  onPressed: () async {
                    final now = DateTime.now();

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate != null &&
                          !startDate!.isAfter(now)
                          ? startDate!
                          : now,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      helpText: "اختر تاريخ البداية",
                      locale: const Locale('ar'),
                    );

                    if (picked != null) {
                      setState(() {
                        startDate = picked;

                        if (endDate != null && endDate!.isBefore(startDate!)) {
                          endDate = startDate;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(endDate != null
                      ? "إلى: ${endDate!.year}-${endDate!.month.toString().padLeft(2,'0')}-${endDate!.day.toString().padLeft(2,'0')}"
                      : "اختر تاريخ النهاية"),
                  onPressed: () async {
                    final now = DateTime.now();

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate != null &&
                          !endDate!.isAfter(now)
                          ? endDate!
                          : now,
                      firstDate: startDate ?? DateTime(2020),
                      lastDate: now,
                      helpText: "اختر تاريخ النهاية",
                      locale: const Locale('ar'),
                    );

                    if (picked != null) {
                      setState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    if (startDate != null && endDate != null) {
                      _loadAbsentAttendances1();
                    } else {
                      CustomSnackBar.show(context,
                          message: "يرجى اختيار تاريخ البداية والنهاية",
                          type: SnackBarType.info);
                    }
                  },
                  child: const Text("بحث"),
                ),
              ],
            ),
            const SizedBox(height: 15),
            CustomSearchBar(
              controller: _searchController,
              hintText: 'ابحث عن موظف...',
              onChanged: _filterEmployees,
              onFilterTap: () {
                CustomSnackBar.show(
                  context,
                  message: "ميزة الفلترة قيد التطوير",
                  type: SnackBarType.info,
                );
              },
            ),
            Expanded(
                child: filteredAbsentAttendances.isEmpty
                    ? const Center(
                  child: Text(
                    "لا يوجد موظفين مطابقون للبحث",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.grey,
                    ),
                  ),
                )
                    :
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredAbsentAttendances.length,
                  itemBuilder: (context, index) {
                    final attendance = filteredAbsentAttendances[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.red.shade100,
                              child: Icon(
                                Icons.person_off,
                                color: Colors.red.shade700,
                                size: 30,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attendance.employeeName ?? "غير معروف",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 5),

                                      Text(
                                        attendance.createdAt != null
                                            ? "${attendance.createdAt!.day}/${attendance.createdAt!.month}/${attendance.createdAt!.year}"
                                            : "-",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),

                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "غائب",
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                /// غياب بعذر
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final TextEditingController reasonController =
                                    TextEditingController();

                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),

                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.help_outline,
                                                color: TColor.primary,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: Text(
                                                    "تأكيد الغياب",
                                                    style: TextStyle(
                                                      fontFamily: 'Tajawal',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          content: Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  "هل تريد تسجيل هذا الغياب كغياب بعذر؟",
                                                  style: TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 16,
                                                  ),
                                                ),

                                                const SizedBox(height: 15),

                                                TextField(
                                                  controller: reasonController,
                                                  maxLines: 3,
                                                  decoration: InputDecoration(
                                                    hintText: "اكتب سبب الغياب...",
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          actionsPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),

                                          actions: [
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: TColor.secondary),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                  horizontal: 20,
                                                ),
                                              ),
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text(
                                                "إلغاء",
                                                style: TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: TColor.secondary,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                  horizontal: 20,
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text(
                                                "تأكيد",
                                                style: TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {

                                      final reason = reasonController.text.trim();

                                      if (reason.isEmpty) {

                                        CustomSnackBar.show(
                                          context,
                                          message: "الرجاء إدخال سبب الغياب",
                                          type: SnackBarType.error,
                                        );

                                        return;
                                      }

                                      final result =
                                      await sl<UpdateAttendanceStatusUseCase>().call(
                                        params: {
                                          "attendanceId": attendance.id,
                                          "status": "present",
                                          "reason": reason,
                                        },
                                      );

                                      result.fold(

                                            (failure) {

                                          CustomSnackBar.show(
                                            context,
                                            message: failure.toString(),
                                            type: SnackBarType.error,
                                          );

                                        },

                                            (_) async {

                                          CustomSnackBar.show(
                                            context,
                                            message: "تم تسجيل الغياب بعذر بنجاح",
                                            type: SnackBarType.success,
                                          );

                                          await _loadAbsentAttendances();

                                        },

                                      );
                                    }                                  },
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text("بعذر"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade50,
                                    foregroundColor: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                /// غياب بدون عذر
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final confirm = await CustomDialog.show(
                                      context,
                                      title: "تأكيد الغياب",
                                      message: "هل تريد تسجيل هذا الغياب كغياب بدون عذر؟",
                                      type: DialogType.confirm,
                                      confirmText: "تأكيد",
                                      cancelText: "إلغاء",
                                    );

                                    if (confirm == true) {

                                      final result = await sl<UpdateAttendanceStatusUseCase>().call(
                                        params: {
                                          "attendanceId": attendance.id,
                                          "status": "absent", // 🔴 reste absent
                                          "reason": "غياب بدون عذر", // 🟡 cause
                                        },
                                      );

                                      result.fold(
                                            (failure) {
                                          CustomSnackBar.show(
                                            context,
                                            message: failure.toString(),
                                            type: SnackBarType.error,
                                          );
                                        },
                                            (_) async {
                                          CustomSnackBar.show(
                                            context,
                                            message: "تم تسجيل الغياب بدون عذر",
                                            type: SnackBarType.success,
                                          );

                                          await _loadAbsentAttendances();
                                        },
                                      );
                                    }                                  },
                                  icon: const Icon(Icons.cancel, size: 18),
                                  label: const Text("بدون عذر"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );                  },
                )


            ),
          ],
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

