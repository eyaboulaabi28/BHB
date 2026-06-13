import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/attendance/AttendancePdfGeneratorAll.dart';
import 'package:app_bhb/presentation/pages/attendance/add_attendance_modal.dart';
import 'package:app_bhb/presentation/pages/attendance/attendance_details_page.dart';
import 'package:app_bhb/presentation/pages/attendance/show_attendance_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  UserCreationReq user = UserCreationReq();
  late final GetEmployeeUseCase _getAllEmployeeUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;
  late final IsEmployeePresentTodayUseCase _isEmployeePresentToday;
  Map<String, bool>? _employeesPresence;
  List<Employees> employees = [];
  List<Employees> filteredEmployees = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();

    _getAllEmployeeUseCase = sl();
    _createNotificationUseCase = sl();
    _isEmployeePresentToday = sl();

    _loadCurrentUserProfile();

    _fetchEmployees().then((_) async {
      await _checkEmployeesPresence();
    });
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

  Future<void> _checkEmployeesPresence() async {
    Map<String, bool> presenceMap = {};
    for (var employee in employees) {
      final isPresent = await sl<IsEmployeePresentTodayUseCase>()
          .call(employee.id!);
      presenceMap[employee.id!] = isPresent;
    }

    if (!mounted) return;

    setState(() {
      _employeesPresence = presenceMap;
    });
  }


  Future<void> generateYesterdayAbsences() async {
    try {
      final now = DateTime.now();

      // ⛔ Ne pas exécuter avant 23h
      if (now.hour < 23) return;

      final yesterday = DateTime(
        now.year,
        now.month,
        now.day - 1,
      );

      final yesterdayDateString =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      // 🔹 Récupérer tous les employés
      final result = await sl<GetEmployeeUseCase>().call();

      await result.fold(
            (failure) async {
          debugPrint("Error loading employees: $failure");
        },
            (employees) async {
          for (var employee in employees) {
            if (employee.id == null) continue;

            // 🔹 Vérifier s’il a déjà une présence ou absence ce jour-là
            final existing = await FirebaseFirestore.instance
                .collection('attendance') // ⚠️ vérifie bien le nom
                .where('employeeId', isEqualTo: employee.id)
                .get();

            bool alreadyExistsForYesterday = false;

            for (var doc in existing.docs) {
              final data = doc.data();

              if (data['startTime'] == null) continue;

              try {
                final date = DateTime.parse(data['startTime']);

                if (date.year == yesterday.year &&
                    date.month == yesterday.month &&
                    date.day == yesterday.day) {
                  alreadyExistsForYesterday = true;
                  break;
                }
              } catch (_) {}
            }

            if (alreadyExistsForYesterday) continue;

            // 🔹 Vérifier si présent
            final isPresent = await sl<IsEmployeePresentTodayUseCase>()
                .call(employee.id!, date: yesterday);

            // 🔴 Si absent → créer absence automatique
            if (!isPresent) {
              await FirebaseFirestore.instance.collection('attendance').add({
                'employeeId': employee.id,
                'employeeName': employee.firstName ?? '',
                'status': 'absent',
                'startTime': yesterday.toIso8601String(),
                'createdAt': FieldValue.serverTimestamp(),
                'notes': "غياب تلقائي (لم يتم تسجيل حضور)",
              });

              debugPrint("Absence created for ${employee.firstName}");
            }
          }
        },
      );
    } catch (e) {
      debugPrint("generateYesterdayAbsences error: $e");
    }
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


 /* Future generateFridayAbsencesOnce({DateTime? testNow}) async {
    final now = testNow ?? DateTime.now();

    debugPrint("🚀 Running at $now");

    final isFriday = now.weekday == DateTime.friday;
    final isAfter23 = now.hour >= 23;

    if (!isFriday || !isAfter23) {
      debugPrint("⛔ Condition not met");
      return;
    }

    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final employeesSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('role', isEqualTo: 'employee')
        .get();

    debugPrint("👥 Employees: ${employeesSnapshot.docs.length}");

    for (final emp in employeesSnapshot.docs) {
      final employeeId = emp.id;
      final docRef = FirebaseFirestore.instance
          .collection('attendance')
          .doc("${employeeId}_$dateKey");

      final existing = await docRef.get();
      if (existing.exists) continue;

      try {
        await docRef.set({
          "employeeId": employeeId,
          "employeeName": emp["firstName"] ?? emp["email"] ?? "",
          "status": "absent",
          "notes": " غياب تلقائي يوم الجمعة عطلة أسبوعية",
          "startTime": now.toIso8601String(),
          "endTime": now.toIso8601String(),
          "workedOnFriday": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        debugPrint("✔ Created for $employeeId");
      } catch (e) {
        debugPrint("❌ Error: $e");
      }
    }
  }*/
  Future<void> generateFridayAbsencesOnce() async {
    final now = DateTime.now();

    debugPrint("🚀 Running Friday auto absence at $now");

    // ❌ pas vendredi → stop
    if (now.weekday != DateTime.friday) {
      debugPrint("⛔ Not Friday");
      return;
    }

    // ❌ avant 23h → stop
    if (now.hour < 23) {
      debugPrint("⛔ Before 23h");
      return;
    }

    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final employeesSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('role', isEqualTo: 'employee')
        .get();

    debugPrint("👥 Employees found: ${employeesSnapshot.docs.length}");

    for (final emp in employeesSnapshot.docs) {
      final employeeId = emp.id;

      final docRef = FirebaseFirestore.instance
          .collection('attendance')
          .doc("${employeeId}_$dateKey");

      final existing = await docRef.get();

      if (existing.exists) {
        debugPrint("✔ Already exists for $employeeId");
        continue;
      }

      try {
        await docRef.set({
          "employeeId": employeeId,
          "employeeName": emp["firstName"] ?? emp["email"] ?? "",
          "status": "absent",
          "notes": "غياب تلقائي يوم الجمعة (عطلة أسبوعية)",
          "startTime": now.toIso8601String(),
          "endTime": now.toIso8601String(),
          "workedOnFriday": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        debugPrint("✔ Absence created for $employeeId");
      } catch (e) {
        debugPrint("❌ Firestore error: $e");
      }
    }
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
            const SizedBox(height: 15),
            // Bouton PDF complet avec texte et icône
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: const Text("تثبيت كامل خاص بإدارة سجل حضور الموظفين"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShowAttendanceDetails(
                      employees: employees,
                      allAttendances: {},
                    ),
                  ),
                );

              },
            ),
            const SizedBox(height: 10), ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("تقرير مفصل حول سجل حضور الموظفين"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                // Récupérer toutes les présences depuis Firestore
                Map<String, List<Attendance>> allAttendances = {};

                for (var employee in employees) {
                  final snapshot = await FirebaseFirestore.instance
                      .collection('attendance')
                      .where('employeeId', isEqualTo: employee.id)
                      .get();

                  final attendanceList = snapshot.docs.map((doc) {
                    return Attendance.fromMap(doc.id, doc.data());
                  }).toList();


                  allAttendances[employee.id!] = attendanceList;
                }

                // Générer le PDF
                await AttendancePdfGeneratorAll.generateAndOpenPdf(
                  employees: employees,
                  allAttendances: allAttendances,
                  context: context,
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
                    :
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    final isAlreadyPresent = _employeesPresence?[employee.id!] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
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
                                          style: const TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 14,
                                              color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 👁️ Bouton détails
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

                                // ➕ Bouton ajouter présence
                                if (!isAlreadyPresent)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                    tooltip: isAlreadyPresent
                                        ? "تم تسجيل الحضور اليوم"
                                        : "إضافة حضور",
                                    onPressed: () {
                                      if (isAlreadyPresent) {
                                        // Afficher le SnackBar si déjà présent
                                        CustomSnackBar.show(
                                          context,
                                          message: "تم تسجيل الحضور اليوم",
                                          type: SnackBarType.info,
                                        );
                                      } else {
                                        // Sinon ouvrir le modal pour ajouter la présence
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => AddAttendanceModal(
                                            title: "إضافة حضور و الانصراف للموظف",
                                            submitButtonText: "إضافة",
                                            employeeId: employee.id!,
                                            initialEmployeeName: employee.firstName,
                                            userRole: user.role ?? "",
                                            onAdd: (values) {

                                              _checkEmployeesPresence();
                                              if (mounted) {
                                                setState(() {});
                                              }

                                            },
                                          ),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

