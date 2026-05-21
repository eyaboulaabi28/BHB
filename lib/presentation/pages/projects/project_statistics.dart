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
  bool isLoading = true;
  List<Employees> employees = [];
  @override
  void initState() {
    super.initState();
    _loadProjectAttendances();
    _loadEmployees();
  }
  Future<void> _loadEmployees() async {

    try {

      final snapshot = await FirebaseFirestore.instance
          .collection('employees')
          .get();

      final data = snapshot.docs.map((doc) {

        return Employees.fromMap(
          doc.id,
          doc.data(),
        );

      }).toList();

      setState(() {
        employees = data;
      });

    } catch (e) {

      debugPrint("Error employees: $e");
    }
  }
  Future<void> _loadProjectAttendances() async {
    try {

      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where(
        'customerName',
        isEqualTo: widget.projectOwnerName,
      )
          .get();

      final data = snapshot.docs.map((doc) {
        return Attendance.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        attendances = data;
        isLoading = false;
      });

    } catch (e) {

      debugPrint("Error statistics: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔹 الموظفين بدون تكرار
  List<String> get uniqueEmployees {

    final names = attendances
        .map((e) => e.employeeName ?? "")
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return names;
  }

  /// 🔹 تحويل النص إلى double
  double parseHours(String? value) {

    if (value == null || value.isEmpty) {
      return 0;
    }

    try {

      final regex = RegExp(r'(\d+)\s*ساعة\s*و\s*(\d+)\s*دقيقة');

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
                "الغيابات",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            DataColumn(
              label: Text(
                "الإجازات",
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

            final employeeData = employees.firstWhere(

                  (e) =>
              (e.firstName ?? "").trim().toLowerCase() ==
                  employeeName.trim().toLowerCase(),

              orElse: () => Employees(
                dailyWage: 0,
              ),
            );

            final employeeAttendances = attendances.where(
                  (e) => e.employeeName == employeeName,
            ).toList();

            final totalDays = employeeAttendances.length;

            final absences = employeeAttendances.where(
                  (e) => e.status == "absent",
            ).length;

            final vacations = employeeAttendances.where(
                  (e) => e.status == "conge",
            ).length;

            final overtimeHours = employeeAttendances.fold<double>(
              0,
                  (sum, item) {
                return sum + parseHours(item.overtimeHours);
              },
            );

            final waitingHours = employeeAttendances.fold<double>(
              0,
                  (sum, item) {
                return sum + parseHours(item.waitingHours);
              },
            );

            final deductions = employeeAttendances.where(
                  (e) => e.hasDeduction == true,
            ).length;
            final dailyWage = employeeData.dailyWage ?? 0;
            debugPrint("Employee: $employeeName");
            debugPrint("Found wage: ${employeeData.dailyWage}");
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

                /// 🔹 الغياب
                DataCell(
                  Row(
                    children: [

                      const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 18,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        "$absences",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 الإجازات
                DataCell(
                  Row(
                    children: [

                      const Icon(
                        Icons.event_busy,
                        color: Colors.orange,
                        size: 18,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        "$vacations",
                        style: const TextStyle(
                          color: Colors.orange,
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
    );
  }
}