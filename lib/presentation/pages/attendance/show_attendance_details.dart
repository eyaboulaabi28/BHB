import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';

import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShowAttendanceDetails extends StatefulWidget {
  final  List<Employees> employees;
  final Map<String, List<Attendance>> allAttendances;

  const ShowAttendanceDetails({super.key, required this.employees,    required this.allAttendances
  });

  @override
  State<ShowAttendanceDetails> createState() => _ShowAttendanceDetailsState();
}

class _ShowAttendanceDetailsState extends State<ShowAttendanceDetails> {
  UserCreationReq user = UserCreationReq();
  List<Employees> employees = [];
  List<Employees> filteredEmployees = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;

  Map<String, List<Attendance>> allAttendances = {};
  String _formatMinutes(double totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = (totalMinutes % 60).round();

    return "$hours ساعة و $minutes دقيقة";
  }

  double _parseHourMinute(String str) {
    int hours = 0;
    int minutes = 0;

    final hourReg = RegExp(r'(\d+)\s*ساعة');
    final minuteReg = RegExp(r'(\d+)\s*دقيقة');

    final hourMatch = hourReg.firstMatch(str);
    final minuteMatch = minuteReg.firstMatch(str);

    if (hourMatch != null) {
      hours = int.parse(hourMatch.group(1)!);
    }

    if (minuteMatch != null) {
      minutes = int.parse(minuteMatch.group(1)!);
    }

    return (hours * 60 + minutes).toDouble();
  }
  @override
  void initState() {
    super.initState();

    _loadCurrentUserProfile();

    employees = widget.employees;

    allAttendances = widget.allAttendances;

    filteredEmployees = employees;

    startDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );

    endDate = DateTime.now();

    _loadAttendances();
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


  Future<void> _loadAttendances() async {
    setState(() {
      isLoading = true;
    });

    final result = await sl<GetAttendanceUseCase>().call();

    result.fold(
          (error) {
        CustomSnackBar.show(
          context,
          message: error.toString(),
          type: SnackBarType.error,
        );
      },
          (data) {
        final attendances = data as List<Attendance>;

        Map<String, List<Attendance>> groupedAttendances = {};

        for (var attendance in attendances) {

          if (attendance.startTime == null) continue;

          // ✅ filtre date
          final attendanceDate = attendance.startTime!;

          final start = DateTime(
            startDate!.year,
            startDate!.month,
            startDate!.day,
          );

          final end = DateTime(
            endDate!.year,
            endDate!.month,
            endDate!.day,
            23,
            59,
            59,
          );

          final isBetween =
              attendanceDate.isAfter(
                  start.subtract(const Duration(days: 1))) &&
                  attendanceDate.isBefore(
                      end.add(const Duration(days: 1)));

          if (!isBetween) continue;

          // ✅ group by employeeId
          groupedAttendances.putIfAbsent(
            attendance.employeeId ?? '',
                () => [],
          );

          groupedAttendances[attendance.employeeId]!
              .add(attendance);
        }

        setState(() {
          allAttendances = groupedAttendances;
        });
      },
    );

    setState(() {
      isLoading = false;
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
                  "تثبيت كامل خاص بإدارة سجل حضور الموظفين",
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
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: (endDate != null &&
                          endDate!.isAfter(DateTime.now()))
                          ? DateTime.now()
                          : endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: "اختر تاريخ النهاية",
                      locale: const Locale('ar'),
                    );
                    if (picked != null) {
                      setState(() => startDate = picked);
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
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: (endDate != null &&
                          endDate!.isAfter(DateTime.now()))
                          ? DateTime.now()
                          : endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: "اختر تاريخ النهاية",
                      locale: const Locale('ar'),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                    onPressed: () {
                      if (startDate != null && endDate != null) {
                        _loadAttendances();
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: "يرجى اختيار تاريخ البداية والنهاية",
                          type: SnackBarType.info,
                        );
                      }
                    },
                  child: const Text("بحث"),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : employees.isEmpty                  ? const Center(
                child: Text(
                  "لا يوجد موظفين",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DataTable(
                      headingRowColor:
                      MaterialStateProperty.all(const Color(0xff022C43)),
                      dataRowColor:
                      MaterialStateProperty.all(Colors.white),
                      border: TableBorder.all(
                        color: const Color(0xffDCE6FF),
                        width: 1,
                      ),
                      columns: const [

                        DataColumn(
                          label: Text(
                            "الموظف",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "عدد أيام الحضور",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "عدد أيام الغياب",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "عدد أيام الاجازة",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "خصم من الدوام",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "سبب الخصم",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "مجموع ساعات العمل الإضافية",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "مجموع ساعات الانتظار",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      rows: employees.map((employee) {

                        final attendances =
                            allAttendances[employee.id] ?? [];

                        final now = DateTime.now();

                        final filteredAttendances = attendances.where((a) {
                          if (a.startTime == null) return false;

                          final attendanceDate = DateTime(
                            a.startTime!.year,
                            a.startTime!.month,
                            a.startTime!.day,
                          );

                          final start = DateTime(
                            startDate!.year,
                            startDate!.month,
                            startDate!.day,
                          );

                          final end = DateTime(
                            endDate!.year,
                            endDate!.month,
                            endDate!.day,
                            23,
                            59,
                            59,
                          );

                          return attendanceDate.isAfter(
                              start.subtract(const Duration(days: 1))) &&
                              attendanceDate.isBefore(
                                  end.add(const Duration(days: 1)));
                        }).toList();

                        final presentDays =
                        filteredAttendances
                            .where((a) => a.status == 'present')
                            .toList();

                        final absentDays =
                        filteredAttendances
                            .where((a) => a.status == 'absent')
                            .toList();

                        final congeDays =
                        filteredAttendances
                            .where((a) => a.status == 'conge')
                            .toList();

                        double totalWaitingMinutes = 0;
                        double totalOvertimeMinutes = 0;

                        for (var a in presentDays) {

                          if (a.waitingHours != null) {
                            totalWaitingMinutes +=
                                _parseHourMinute(
                                    a.waitingHours!);
                          }

                          if (a.overtimeHours != null) {
                            totalOvertimeMinutes +=
                                _parseHourMinute(
                                    a.overtimeHours!);
                          }
                        }

                        final waitingFormatted =
                        _formatMinutes(
                            totalWaitingMinutes);

                        final overtimeFormatted =
                        _formatMinutes(
                            totalOvertimeMinutes);

                        String deductionText = "لا";
                        String deductionReason = "-";

                        final deductions = presentDays
                            .where((a) => a.hasDeduction == true)
                            .toList();

                        if (deductions.isNotEmpty) {
                          deductionText = "نعم";

                          deductionReason = deductions
                              .map((e) =>
                          e.deductionReason ?? "-")
                              .join(" , ");
                        }

                        return DataRow(
                          cells: [

                            DataCell(
                              Text(employee.firstName ?? "-"),
                            ),

                            DataCell(
                              Text(
                                presentDays.length.toString(),
                              ),
                            ),

                            DataCell(
                              Text(
                                absentDays.length.toString(),
                              ),
                            ),

                            DataCell(
                              Text(
                                congeDays.length.toString(),
                              ),
                            ),

                            DataCell(
                              Text(deductionText),
                            ),

                            DataCell(
                              Text(deductionReason),
                            ),

                            DataCell(
                              Text(overtimeFormatted),
                            ),

                            DataCell(
                              Text(waitingFormatted),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),

      ),
    );
  }

}


