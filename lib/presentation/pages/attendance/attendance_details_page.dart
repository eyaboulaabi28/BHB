import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:app_bhb/presentation/pages/attendance/generate_pdf_attendance.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';


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
  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ✅ Début du mois actuel
    startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

    // ✅ Fin du mois actuel
    endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    _loadAttendancesByDateRange();
  }

  Future<void> _loadAttendancesByDateRange() async {
    if (startDate == null || endDate == null) {
      CustomSnackBar.show(
        context,
        message: "يرجى اختيار تاريخ البداية والنهاية",
        type: SnackBarType.info,
      );
      return;
    }

    setState(() => isLoading = true);

    // ✅ ضبط بداية اليوم
    final start = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      0, 0, 0,
    );

    // ✅ ضبط نهاية اليوم 23:59:59
    final end = DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
      23, 59, 59,
    );

    final result = await sl<GetAttendanceByEmployeeAndMonthUseCase>().call(
      params: {
        'employeeId': widget.employee.id,
        'start': start,
        'end': end,
      },
    );

    result.fold(
          (l) => CustomSnackBar.show(context, message: l, type: SnackBarType.error),
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
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: "اختر تاريخ البداية",
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
                      initialDate: endDate ?? DateTime.now(),
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
                      _loadAttendancesByDateRange();
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
            // Bouton PDF complet avec texte et icône
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("تقرير مفصل حول سجل حضور الموظف"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (startDate != null && endDate != null) {
                  await AttendancePdfGenerator.generateAndOpenPdf(
                    attendances: attendances,
                    employeeName: widget.employee.firstName ?? "",
                    startDate: startDate!,
                    endDate: endDate!,
                    context: context,
                  );
                } else {
                  CustomSnackBar.show(context,
                      message: "يرجى اختيار تاريخ البداية والنهاية",
                      type: SnackBarType.info);
                }
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
                                if (a.waitingHours != null && a.waitingHours!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, size: 20, color: Colors.blue),
                                      const SizedBox(width: 5),
                                      Text(
                                        "عدد ساعات الانتظار: ${a.waitingHours!}",
                                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                                      ),
                                    ],
                                  ),

                                if (a.overtimeHours != null && a.overtimeHours!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, size: 20, color: Colors.blue),
                                      const SizedBox(width: 5),
                                      Text(
                                        "عدد الساعات الإضافية: ${a.overtimeHours!}",
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
                                          "التاريخ: ${_formatDateTime(a.endTime)}",
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
                                    const SizedBox(height: 5),

                                    if (a.status != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          Row(
                                            children: [
                                              Icon(
                                                a.status == 'present'
                                                    ? Icons.check_circle
                                                    : a.status == 'conge'
                                                    ? Icons.beach_access
                                                    : Icons.cancel,
                                                color: a.status == 'present'
                                                    ? Colors.green
                                                    : a.status == 'conge'
                                                    ? Colors.orange
                                                    : Colors.red,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                a.status == 'present'
                                                    ? "حاضر"
                                                    : a.status == 'conge'
                                                    ? "إجازة"
                                                    : "غائب",
                                                style: const TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 5),

                                          /// 🔴 ABSENCE REASON (NEW)
                                          if (a.absenceReason != null &&
                                              a.absenceReason!.trim().isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(top: 5),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.red.shade200),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.info_outline,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      a.absenceReason!,
                                                      style: const TextStyle(
                                                        fontFamily: 'Tajawal',
                                                        fontSize: 13,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),

                                    if ((a.notes ?? "").isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: a.notes!.contains("غياب")
                                              ? Colors.red.shade50
                                              : Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: a.notes!.contains("غياب")
                                                ? Colors.red.shade200
                                                : Colors.green.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              a.notes!.contains("غياب")
                                                  ? Icons.event_busy
                                                  : Icons.work_history,
                                              color: a.notes!.contains("غياب")
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                a.notes!,
                                                style: const TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.grey),
                                            SizedBox(width: 10),
                                            Text(
                                              " لا يوجد ملاحظات",
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
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


