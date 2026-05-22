import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProjectStatistics extends StatefulWidget {
  final String projectOwnerName;

  const ProjectStatistics({
    super.key,
    required this.projectOwnerName,
  });

  @override
  State<ProjectStatistics> createState() => _ProjectStatisticsState();
}

class _ProjectStatisticsState extends State<ProjectStatistics> {
  List<Attendance> attendances = [];
  List<Employees> employees = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 🔹 تحميل البيانات
  Future<void> _loadData() async {
    try {
      /// 🔹 الموظفين
      final employeesSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'employee')
          .get();

      final employeesData = employeesSnapshot.docs.map((doc) {
        return Employees.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();

      /// 🔹 الحضور
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where(
        'customerName',
        isEqualTo: widget.projectOwnerName,
      )
          .get();

      final attendanceData = attendanceSnapshot.docs.map((doc) {
        return Attendance.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();

      setState(() {
        employees = employeesData;
        attendances = attendanceData;
        isLoading = false;
      });

      debugPrint("========== EMPLOYEES ==========");

      for (var emp in employees) {
        debugPrint(
          "ID: ${emp.id} | Name: ${emp.firstName} | Wage: ${emp.dailyWage}",
        );
      }

      debugPrint("========== ATTENDANCES ==========");

      for (var att in attendances) {
        debugPrint(
          "EmployeeId: ${att.employeeId} | EmployeeName: ${att.employeeName}",
        );
      }
    } catch (e) {
      debugPrint("ERROR: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔹 أسماء الموظفين بدون تكرار
  List<String> get uniqueEmployees {
    return attendances
        .map((e) => e.employeeName ?? "")
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  /// 🔹 تحويل النص إلى double
  double parseHours(String? value) {
    if (value == null || value.isEmpty) {
      return 0;
    }

    try {
      final regex = RegExp(
        r'(\d+)\s*ساعة\s*و\s*(\d+)\s*دقيقة',
      );

      final match = regex.firstMatch(value);

      if (match != null) {
        final hours = int.parse(match.group(1)!);

        final minutes = int.parse(match.group(2)!);

        return hours + (minutes / 60);
      }

      return double.tryParse(
        value.replaceAll(',', '.'),
      ) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (attendances.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد بيانات حضور لهذا المشروع",
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          border: TableBorder.all(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),

          headingRowColor: MaterialStateProperty.all(
            Colors.blue.withOpacity(0.1),
          ),

          dataRowColor: MaterialStateProperty.all(
            Colors.white,
          ),

          columnSpacing: 25,
          horizontalMargin: 16,

          columns: const [
            DataColumn(
              label: Text(
                "الموظف",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            DataColumn(
              label: Text(
                "أيام العمل",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),


            DataColumn(
              label: Text(
                "التكلفة",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          rows: uniqueEmployees.map((employeeName) {

            /// 🔹 سجلات الموظف
            final employeeAttendances = attendances.where(
                  (e) => e.employeeName == employeeName,
            ).toList();

            /// 🔹 employeeId
            final employeeId = employeeAttendances.isNotEmpty
                ? employeeAttendances.first.employeeId
                : null;

            Employees? employeeData;

            try {

              /// 🔹 البحث بالـ ID
              employeeData = employees.firstWhere(
                    (e) => e.id == employeeId,
              );

            } catch (_) {

              try {

                /// 🔹 fallback بالاسم
                employeeData = employees.firstWhere(
                      (e) =>
                      (e.firstName ?? "")
                          .trim()
                          .toLowerCase()
                          .contains(
                        employeeName.trim().toLowerCase(),
                      ),
                );

              } catch (_) {

                employeeData = Employees(
                  dailyWage: 0,
                );
              }
            }

            debugPrint("========== MATCH ==========");
            debugPrint("Employee Name: $employeeName");
            debugPrint("Employee ID: $employeeId");
            debugPrint("Found Wage: ${employeeData.dailyWage}");

            /// 🔹 أيام الحضور فقط
            final totalDays = employeeAttendances.where(
                  (e) => e.status == "present",
            ).length;

            /// 🔹 الغيابات
            final absences = employeeAttendances.where(
                  (e) => e.status == "absent",
            ).length;

            /// 🔹 الإجازات
            final vacations = employeeAttendances.where(
                  (e) => e.status == "conge",
            ).length;

            /// 🔹 الأجر اليومي
            final dailyWage = employeeData.dailyWage ?? 0;

            /// 🔹 التكلفة
            final totalCost = totalDays * dailyWage;

            return DataRow(
              cells: [

                /// 🔹 الموظف
                DataCell(
                  Row(
                    children: [

                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                        Colors.blue.withOpacity(0.15),

                        child: const Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 أيام العمل
                DataCell(
                  Row(
                    children: [

                      const Icon(
                        Icons.calendar_month,
                        color: Colors.green,
                        size: 18,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        "$totalDays",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),



                /// 🔹 التكلفة
                DataCell(
                  Row(
                    children: [

                      const Icon(
                        Icons.attach_money,
                        color: Colors.teal,
                        size: 18,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        "${totalCost.toStringAsFixed(2)} د.ت",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}