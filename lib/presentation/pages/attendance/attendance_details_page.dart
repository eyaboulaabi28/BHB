import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:app_bhb/presentation/pages/attendance/generate_pdf_attendance.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class AttendanceDetailsPage extends StatefulWidget {
  final String selectedType;
  final String projectName;
  final Employees employee;
  const AttendanceDetailsPage({
    super.key,required this.selectedType,
    required this.projectName,
    required this.employee,

  });

  @override
  State<AttendanceDetailsPage> createState() => _AttendanceDetailsPageState();
}

class _AttendanceDetailsPageState extends State<AttendanceDetailsPage> {
  int _selectedIndex = 0;
  DateTime selectedMonth = DateTime.now();
  List<Attendance> attendances = [];
  bool isLoading = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }
  Future<void> _loadAttendances() async {
    setState(() => isLoading = true);

    final result = await sl<GetAttendanceByEmployeeAndMonthUseCase>().call(
      params: {
        'employeeId': widget.employee.id,
        'month': selectedMonth,
      },
    );

    result.fold(
          (l) {
        // Affiche l'erreur dans la console
        print("Erreur lors du chargement des présences : $l");
        // Affiche l'erreur dans le SnackBar
        CustomSnackBar.show(context, message: l, type: SnackBarType.error);
      },
          (r) => setState(() => attendances = List<Attendance>.from(r)),
    );

    setState(() => isLoading = false);
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "-";
    return "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "-";
    return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}";
  }

  String formatMinutesToHours(double? minutes) {
    if (minutes == null) return "-";
    double hours = minutes / 60.0;
    return hours.toStringAsFixed(2);
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
                  "تفاصيل الحضور",
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
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text("${selectedMonth.year}-${selectedMonth.month}"),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  helpText: "اختر الشهر",
                  locale: const Locale('ar'),
                  builder: (context, child) {
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  setState(() => selectedMonth = picked);
                  _loadAttendances();
                }
              },
            ),
            const SizedBox(height: 15),
            // Bouton PDF complet avec texte et icône
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
              label: const Text(
                "تقرير مفصل حول سجل حضور الموظف",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                // ✅ Appel simple de la classe, tout est géré à l'intérieur
                await AttendancePdfGenerator.generateAndOpenPdf(
                  attendances: attendances,
                  employeeName: widget.employee.firstName ?? "",
                  month: selectedMonth,
                  context: context, // pour pouvoir afficher SnackBar si nécessaire
                );
              },
            ),


            const SizedBox(height: 15),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendances.isEmpty
                  ? const Center(child: Text("لا توجد بيانات لهذا الشهر"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: attendances.length,
                itemBuilder: (context, index) {
                  final a = attendances[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ====== Colonne de gauche ======
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Employee Name + Date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "الموظف: ${a.employeeName ?? "-"}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),                                const Divider(height: 20, thickness: 1),

                                // Horaires
                                Row(
                                  children: [
                                    const Icon(Icons.login, size: 20, color: Colors.green),
                                    const SizedBox(width: 5),
                                    Text(
                                      "بداية الدوام: ${a.startTime != null ? "${a.startTime!.hour}:${a.startTime!.minute.toString().padLeft(2,'0')}" : "-"}",
                                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.logout, size: 20, color: Colors.red),
                                    const SizedBox(width: 5),
                                    Text(
                                      "نهاية الدوام: ${a.endTime != null ? "${a.endTime!.hour}:${a.endTime!.minute.toString().padLeft(2,'0')}" : "-"}",
                                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Waiting & Overtime
                                // Waiting & Overtime
                                if (a.waitingHours != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, size: 20, color: Colors.blue),
                                      const SizedBox(width: 5),
                                      Text(
                                        "عدد ساعات الانتظار: ${formatMinutesToHours(a.waitingHours)} ساعة",
                                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                                      ),
                                    ],
                                  ),
                                if (a.overtimeHours != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, size: 20, color: Colors.blue),
                                      const SizedBox(width: 5),
                                      Text(
                                        "عدد الساعات الإضافية: ${formatMinutesToHours(a.overtimeHours)} ساعة",
                                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 10),

                                // Customer
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 20, color: Colors.orange),
                                    const SizedBox(width: 5),
                                    Text(
                                      "العميل: ${a.customerName ?? '-'}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.date_range_outlined, size: 20, color: Colors.black),
                                        const SizedBox(width: 5),
                                        Text(
                                          "التاريخ: ${_formatDateTime(a.createdAt)}",
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 20, color: Colors.black),
                                        const SizedBox(width: 5),
                                        Text(
                                          "الساعة: ${_formatTime(a.createdAt)}",
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),




                              ],
                            ),
                          ),

                          const SizedBox(width: 15),

                          // ====== Colonne de droite ======
                          if (a.signatureUrl != null && a.signatureUrl!.isNotEmpty)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    "التوقيع الإلكتروني:",
                                    style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 120, // tu peux ajuster selon ton besoin
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        a.signatureUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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


