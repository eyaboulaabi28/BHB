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

    /// ===============================
    /// Statistiques globales du projet
    /// ===============================

    final int totalProjectDays = attendances
        .where((e) => e.status == "present")
        .length;

    final int totalAbsences = attendances
        .where((e) => e.status == "absent")
        .length;

    final int totalVacations = attendances
        .where((e) => e.status == "conge")
        .length;

    double totalProjectCost = 0;

    /// Calcul du coût total
    for (final employeeName in uniqueEmployees) {
      final employeeAttendances = attendances
          .where((e) => e.employeeName == employeeName)
          .toList();

      final employeeId = employeeAttendances.isNotEmpty
          ? employeeAttendances.first.employeeId
          : null;

      Employees? employeeData;

      try {
        employeeData = employees.firstWhere(
              (e) => e.id == employeeId,
        );
      } catch (_) {
        try {
          employeeData = employees.firstWhere(
                (e) => (e.firstName ?? "")
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

      final totalDays = employeeAttendances
          .where((e) => e.status == "present")
          .length;

      final dailyWage = employeeData.dailyWage ?? 0;

      totalProjectCost += totalDays * dailyWage;
    }

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          /// ===============================
          /// Résumé du projet
          /// ===============================
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.blue.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard(
                  icon: Icons.calendar_month,
                  color: Colors.green,
                  title: "أيام العمل",
                  value: "$totalProjectDays",
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  icon: Icons.attach_money,
                  color: Colors.teal,
                  title: "تكلفة المشروع",
                  value: "${totalProjectCost.toStringAsFixed(2)} د.ت",
                ),
              ],
            ),          ),

          /// ===============================
          /// Tableau
          /// ==============================

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: DataTable(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      headingRowColor: WidgetStateProperty.all(
                        Colors.blue.withOpacity(0.1),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            "الموظف",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "أيام العمل",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "التكلفة",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: uniqueEmployees.map((employeeName) {
                        final employeeAttendances = attendances
                            .where((e) => e.employeeName == employeeName)
                            .toList();

                        final employeeId = employeeAttendances.isNotEmpty
                            ? employeeAttendances.first.employeeId
                            : null;

                        Employees? employeeData;

                        try {
                          employeeData = employees.firstWhere(
                                (e) => e.id == employeeId,
                          );
                        } catch (_) {
                          employeeData = Employees(dailyWage: 0);
                        }

                        final totalDays = employeeAttendances
                            .where((e) => e.status == "present")
                            .length;

                        final dailyWage = employeeData.dailyWage ?? 0;

                        final totalCost = totalDays * dailyWage;

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.blue.withOpacity(0.15),
                                    child: const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    employeeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
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
                ),
              )            ],
          ),
        ),
    );
  }
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return SizedBox(
      width: 140,
      height: 130, // 👈 FIX HEIGHT IMPORTANT
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 👈 centre vertical
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 25,
            ),
            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis, // 👈 empêche débordement
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}