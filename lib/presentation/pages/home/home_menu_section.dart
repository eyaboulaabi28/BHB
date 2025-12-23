import 'package:app_bhb/presentation/pages/check-in/check_in_page.dart';
import 'package:app_bhb/presentation/pages/contact_us/contact_page.dart';
import 'package:app_bhb/presentation/pages/customers/customers_page.dart';
import 'package:app_bhb/presentation/pages/daily_tasks/daily_tasks_page.dart';
import 'package:app_bhb/presentation/pages/electronic_signature/electronic_signature_page.dart';
import 'package:app_bhb/presentation/pages/employees/employees_page.dart';
import 'package:app_bhb/presentation/pages/engineers/engineers_page.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/engineer_evaluation_page.dart';
import 'package:app_bhb/presentation/pages/materials/materials_page.dart';
import 'package:app_bhb/presentation/pages/meeting/meeting_page.dart';
import 'package:app_bhb/presentation/pages/projects/projects_page.dart';
import 'package:app_bhb/presentation/pages/settings/settings_page.dart';
import 'package:app_bhb/presentation/pages/vacation/vacation_page.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';

class HomeMenuSection extends StatelessWidget {
  final String selectedType;
  final String userRole;
  const HomeMenuSection({super.key, required this.selectedType, required this.userRole});

  @override
  Widget build(BuildContext context) {


    List<Map<String, dynamic>> getMenuItems(String role) {
      final allItems = [
        {
          "icon": Icons.engineering,
          "color": Colors.red.shade100,
          "title": "إدارة المهندسين",
          "page": const EngineersPage(selectedType: ""),
          "roles": ["admin"]
        },
        {
          "icon": Icons.group,
          "color": Colors.blue.shade100,
          "title": " إدارة العملاء ",
          "page": const CustomersPage(selectedType: ""),
          "roles": ["admin", "resource",],
        },
        {
          "icon": Icons.manage_accounts,
          "color": Colors.green.shade50,
          "title": "إدارة الموظفين",
          "page": const EmployeesPage(selectedType: ""),
          "roles": ["admin"],
        },
        {
          "icon": Icons.inventory,
          "color": Colors.orangeAccent.shade100,
          "title": "إدارة المواد",
          "page": const MaterialsPage(selectedType: ""),
          "roles": ["admin", "resource",],

        },
        {
          "icon": Icons.list_alt,
          "color": Colors.yellowAccent.shade100,
          "title": "عرض المشاريع",
          "page": ProjectsPage(selectedType: selectedType,userRole:userRole),
          "roles": ["admin", "engineer", "customer"],

        },
        {
          "icon": Icons.bar_chart,
          "color": Colors.brown.shade100,
          "title": "تقرير الحضور",
          "page": CheckInPage(selectedType: ""),
          "roles": ["admin","engineer"],
        },
        {
          "icon": Icons.calendar_today,
          "color": Colors.lightBlue.shade100,
          "title": "الجداول اليومية",
          "page": DailyTasksPage(selectedType: ""),
          "roles": ["admin","engineer"],

        },
        {
          "icon": Icons.rate_review,
          "color": Colors.purple.shade100,
          "title": "تقييم الفنيين",
          "page": EngineerEvaluationPage(selectedType: ""),
          "roles": ["admin"],
        },
        {
          "icon": Icons.insert_drive_file,
          "color": Colors.deepPurple.shade100,
          "title": "محاضر الاجتماعات",
          "page": const MeetingPage(selectedType: ""),
          "roles": ["admin", "engineer", "customer"],
        },
        {
          "icon": Icons.settings,
          "color": Colors.lightGreenAccent.shade100,
          "title": "الإعدادات العامة",
          "page": const SettingsPage(selectedType: ""),
          "roles": ["admin",],
        },
        {
          "icon": Icons.schedule,
          "color": Colors.redAccent.shade100,
          "title": "إعدادات العطل",
          "page": const VacationPage(selectedType: ""),
          "roles": ["admin"],
        },
        {
          "icon": Icons.phone,
          "color": Colors.orange.shade50,
          "title": "تواصل معنا",
          "page": const ContactPage(selectedType: ""),
          "roles": ["admin", "engineer", "customer"]
        },
        {
          "icon": Icons.edit_note,
          "color": Colors.teal.shade100,
          "title": "التوقيع الإلكتروني",
          "page": const ElectronicSignaturePage(selectedType: ""),
          "roles": ["admin","engineer", "customer"],
        },

      ];
      return allItems.where((item) {
        final roles = item["roles"] as List<String>;
        return roles.contains(role.toLowerCase());
      }).toList();
    }
    final menuItems = getMenuItems(userRole);
    return Padding(
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
                  // Icône circulaire colorée
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
                  // Titre
                  Text(
                    item["title"],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajwal',
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
    );
  }
}
