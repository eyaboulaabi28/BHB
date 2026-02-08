import 'package:app_bhb/data/auth/models/date_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_date.dart';
import 'package:app_bhb/presentation/pages/attendance/attendance_page.dart';
import 'package:app_bhb/presentation/pages/check-in/check_in_page.dart';
import 'package:app_bhb/presentation/pages/contact_us/contact_page.dart';
import 'package:app_bhb/presentation/pages/customers/customers_page.dart';
import 'package:app_bhb/presentation/pages/daily_tasks/daily_tasks_page.dart';
import 'package:app_bhb/presentation/pages/dates/dates_page.dart';
import 'package:app_bhb/presentation/pages/electronic_signature/electronic_signature_page.dart';
import 'package:app_bhb/presentation/pages/employees/employees_page.dart';
import 'package:app_bhb/presentation/pages/engineers/engineers_page.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/engineer_evaluation_page.dart';
import 'package:app_bhb/presentation/pages/materials/materials_page.dart';
import 'package:app_bhb/presentation/pages/meeting/meeting_page.dart';
import 'package:app_bhb/presentation/pages/new_site/new_site_page.dart';
import 'package:app_bhb/presentation/pages/projects/projects_page.dart';
import 'package:app_bhb/presentation/pages/settings/settings_page.dart';
import 'package:app_bhb/presentation/pages/vacation/vacation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';

import '../../../service_locator.dart';

class HomeMenuSection extends StatefulWidget {
  final String selectedType;
  final String userRole;
  final String projectName;

  const HomeMenuSection({
    super.key,
    required this.selectedType,
    required this.userRole,
    required this.projectName,
  });

  @override
  State<HomeMenuSection> createState() => _HomeMenuSectionState();
}

class _HomeMenuSectionState extends State<HomeMenuSection> {
  List<Date> pendingDates = [];
  bool isLoading = true;
  List<Date> lateDates = [];

  @override
  void initState() {
    super.initState();

    if (widget.userRole == "admin" || widget.userRole == "engineer") {
      _fetchPendingDates();
    } else {
      isLoading = false;
    }
  }

  bool isLate(Date d) {
    if (d.createdAt == null) return false;

    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    return d.createdAt!.isBefore(dateOnly) &&
        d.status != DateStatus.completed &&
        d.status != DateStatus.cancelled;
  }

  Future<void> _fetchPendingDates() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final result = await sl<GetDateUseCase>().call(
      userId: uid,
      role: widget.userRole,
    );

    result.fold(
          (_) => setState(() => isLoading = false),
          (list) {
        setState(() {
          pendingDates = list
              .where((d) => d.status == DateStatus.pending)
              .where((d) => !isLate(d))
              .toList();

          lateDates = list
              .where((d) => d.status == DateStatus.late)
              .toList();

          isLoading = false;
        });
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> getMenuItems(String role) {
      final allItems = [
        {
          "icon": Icons.engineering,
          "color": Colors.red.shade100,
          "title": "إدارة المهندسين",
          "page": const EngineersPage(selectedType: "",projectName: "",),
          "roles": ["admin"]
        },
        {
          "icon": Icons.group,
          "color": Colors.blue.shade100,
          "title": " إدارة العملاء ",
          "page": const CustomersPage(selectedType: "",projectName: "",),
          "roles": ["admin", "resource",],
        },
        {
          "icon": Icons.manage_accounts,
          "color": Colors.green.shade50,
          "title": "إدارة الموظفين",
          "page": const EmployeesPage(selectedType: "",projectName: "",),
          "roles": ["admin","engineer",],
        },
        {
          "icon": Icons.inventory,
          "color": Colors.orangeAccent.shade100,
          "title": "إدارة المواد",
          "page": const MaterialsPage(selectedType: "",projectName: "",),
          "roles": ["admin", "resource",],

        },
        {
          "icon": Icons.list_alt,
          "color": Colors.yellowAccent.shade100,
          "title": "عرض المشاريع",
          "page": ProjectsPage(selectedType: widget.selectedType,userRole:widget.userRole,projectName: "",),
          "roles": ["admin", "engineer", "customer"],

        },
        {
          "icon": Icons.bar_chart,
          "color": Colors.brown.shade100,
          "title": "تقرير الحضور",
          "page": CheckInPage(selectedType: "",projectName: "",),
          "roles": ["admin","engineer"],
        },
        {
          "icon": Icons.calendar_today,
          "color": Colors.lightBlue.shade100,
          "title": "الجداول اليومية",
          "page": DailyTasksPage(selectedType: "",projectName: "",),
          "roles": ["admin","engineer"],

        },
        {
          "icon": Icons.rate_review,
          "color": Colors.purple.shade100,
          "title": "تقييم الفنيين",
          "page": EngineerEvaluationPage(selectedType: "",projectName: "",),
          "roles": ["admin"],
        },
        {
          "icon": Icons.insert_drive_file,
          "color": Colors.deepPurple.shade100,
          "title": "محاضر الاجتماعات",
          "page": const MeetingPage(selectedType: "",projectName: "",),
          "roles": ["admin", "engineer", "customer"],
        },
        {
          "icon": Icons.settings,
          "color": Colors.lightGreenAccent.shade100,
          "title": "الإعدادات العامة",
          "page": const SettingsPage(selectedType: "",projectName: "",),
          "roles": ["admin",],
        },
        {
          "icon": Icons.schedule,
          "color": Colors.redAccent.shade100,
          "title": "إعدادات العطل",
          "page": const VacationPage(selectedType: "",projectName: "",),
          "roles": ["admin"],
        },
        {
          "icon": Icons.phone,
          "color": Colors.orange.shade50,
          "title": "تواصل معنا",
          "page": const ContactPage(selectedType: "",projectName: "",),
          "roles": ["admin", "engineer", "customer"]
        },
        {
          "icon": Icons.edit_note,
          "color": Colors.teal.shade100,
          "title": "التوقيع الإلكتروني",
          "page": const ElectronicSignaturePage(selectedType: "",projectName: "",),
          "roles": ["admin","engineer", "customer"],
        },
        {
          "icon": Icons.access_alarm_outlined,
          "color": Colors.blueGrey.shade100,
          "title": "حضور و انصراف",
          "page": AttendancePage(selectedType: "",projectName: "",),
          "roles": ["admin", "engineer"],
        },
        {
          "icon": Icons.calendar_month_sharp,
          "color": Colors.brown.shade200,
          "title": "المواعيد",
          "page": DatesPage(selectedType: "",projectName: "",),
          "roles": ["admin", "engineer","customer"],
        },
        {
          "icon": Icons.location_on_outlined,
          "color": Colors.orange.shade200,
          "title": "زيارة موقع جديد",
          "page": NewSitePage(selectedType: "", projectName: ""),
          "roles": ["admin", "engineer",],
        },



      ];
      return allItems.where((item) {
        final roles = item["roles"] as List<String>;
        return roles.contains(role.toLowerCase());
      }).toList();
    }


    final menuItems = getMenuItems(widget.userRole);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔔 Box تذكير المواعيد (admin + engineer فقط)
          if (!isLoading && (widget.userRole == "admin" || widget.userRole == "engineer"))
            _pendingDatesBox(),

          if (!isLoading && (widget.userRole == "admin" || widget.userRole == "engineer"))
            _lateDatesBox(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (item["page"] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => item["page"]),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: item["color"],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item["icon"],
                            color: TColor.secondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item["title"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: TColor.primaryText,
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
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
  String _remainingDaysText(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day)).inDays;

    if (difference > 0) {
      return "يتبقى $difference يومًا حتى الموعد.";
    } else if (difference == 0) {
      return "اليوم هو موعدك!";
    } else {
      return "انتهى الموعد منذ ${-difference} يومًا.";
    }
  }

  Widget _pendingDatesBox() {
    if (pendingDates.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_active, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "مواعيد قيد الانتظار",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...pendingDates.take(4).map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${d.customerName ?? "بدون اسم"} - ${_remainingDaysText(d.createdAt)}",
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),


          if (pendingDates.length > 4)
            Text(
              "و ${pendingDates.length - 4} مواعيد أخرى...",
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

        ],
      ),
    );
  }
  Widget _lateDatesBox() {
    if (lateDates.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "مواعيد متأخرة",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...lateDates.take(4).map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.event_busy, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${d.customerName ?? "بدون اسم"} - ${_remainingDaysText(d.createdAt)}",
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),

          if (lateDates.length > 4)
            Text(
              "و ${lateDates.length - 4} مواعيد أخرى...",
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }


}


