import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/attendance/add_attendance_modal.dart';
import 'package:app_bhb/presentation/pages/attendance/attendance_details_page.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:app_bhb/presentation/pages/employees/add_employee_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal;
import 'package:geocoding/geocoding.dart';
import '../../../service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AttendancePage extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const AttendancePage({super.key, required this.selectedType,    required this.projectName
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  int _selectedIndex = 0;

  late final GetEmployeeUseCase _getAllEmployeeUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;

  List<Employees> employees = [];
  List<Employees> filteredEmployees = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getAllEmployeeUseCase = sl<GetEmployeeUseCase>();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    final result = await _getAllEmployeeUseCase.call();

    result.fold(
          (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $failure")),
        );
      },
          (employeeList) {
        setState(() {
          employees = List<Employees>.from(employeeList);
          filteredEmployees = employees;
        });
      },
    );
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees
            .where((e) =>
        (e.firstName ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.email ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.role ?? "").toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }


  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
                  "إدارة الحضور و الانصراف",
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
            const SizedBox(height: 10),
            Expanded(
              child: filteredEmployees.isEmpty
                  ? const Center(
                child: Text(
                  "لا يوجد موظفين مطابقون للبحث",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child:
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: TColor.secondary.withOpacity(0.2),
                              child: Icon(Icons.manage_accounts, color: TColor.primary),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employee.firstName ?? "",
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    employee.email ?? "",
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          employee.phone ?? "",
                                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // ✅ Nouveau bouton Add
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 👁️ زر التفاصيل
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: Colors.blue,
                                    size: 26,
                                  ),
                                  tooltip: "عرض التفاصيل",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AttendanceDetailsPage(
                                          employee: employee,
                                          selectedType: widget.selectedType,
                                          projectName: widget.projectName,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // ➕ زر إضافة الحضور
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  tooltip: "إضافة حضور",
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => AddAttendanceModal(
                                        title: "إضافة حضور و الانصراف للموظف",
                                        submitButtonText: "إضافة",
                                        employeeId: employee.id!,
                                        onAdd: (values) {
                                          setState(() {
                                          });
                                        },
                                        // ✅ Passer le nom de l'employé
                                        initialEmployeeName: employee.firstName,
                                      ),

                                    );
                                  },
                                ),
                              ],
                            ),

                          ],
                        )

                      ),
                    );

                  }),
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

