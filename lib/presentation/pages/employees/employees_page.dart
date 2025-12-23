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

class EmployeesPage extends StatefulWidget {
  final String selectedType;

  const EmployeesPage({super.key, required this.selectedType});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  int _selectedIndex = 0;

  late final GetEmployeeUseCase _getAllEmployeeUseCase;
  late final DeleteEmployeerUseCase _deleteEmployeeUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;

  List<Employees> employees = [];
  List<Employees> filteredEmployees = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getAllEmployeeUseCase = sl<GetEmployeeUseCase>();
    _deleteEmployeeUseCase = sl<DeleteEmployeerUseCase>();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _fetchEmployees();
  }

  Future<void> _sendNotification({
    required String title,
    required String message,
    String? route,
    String? userId,
  }) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      createdAt: DateTime.now(),
      userId: userId,
      route: route,
      isRead: false,
    );

    await _createNotificationUseCase.call(notification: notif);
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

  Future<void> _deleteEmployee(String employeeId) async {
    final result = await _deleteEmployeeUseCase.call(params: employeeId);

    final deletedEmployee =
    employees.firstWhere((e) => e.id == employeeId, orElse: () => Employees());

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "خطأ  في الحذف  : $failure",
          type: SnackBarType.error,
        );
      },
          (_) async {
        setState(() {
          employees.removeWhere((e) => e.id == employeeId);
        });

        CustomSnackBar.show(
          context,
          message: "تم حذف الموظف بنجاح",
          type: SnackBarType.success,
        );

        await _sendNotification(
          title: "حذف موظف",
          message: "تم حذف موظف من النظام: ${deletedEmployee.firstName ?? ""}",
          route: "/home",
          userId: employeeId,
        );
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {

      if (kIsWeb) {
        final url = Uri.parse(
            "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=ar");

        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data["display_name"] ?? "غير معروف";
        } else {
          return "غير معروف";
        }
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return "غير معروف";

      final p = placemarks.first;

      final locality = p.locality ?? "";
      final street = p.street ?? "";
      final country = p.country ?? "";

      if (locality.isEmpty && street.isEmpty && country.isEmpty) {
        return "غير معروف";
      }

      return "$locality - $street - $country".trim();
    } catch (e) {
      print("Reverse Geocoding Error: $e");
      return "غير معروف";
    }
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
                  "إدارة الموظفين",
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
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor:
                              TColor.secondary.withOpacity(0.2),
                              child: Icon(Icons.manage_accounts,
                                  color: TColor.primary),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                                  const SizedBox(height: 5),
                                  if (employee.latitude != null && employee.longitude != null)
                                    FutureBuilder<String>(
                                      future: getAddressFromLatLng(employee.latitude!, employee.longitude!),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Row(
                                            children: const [
                                              Icon(Icons.location_on, size: 16, color: Colors.grey),
                                              SizedBox(width: 5),
                                              Text("جاري جلب الموقع...",
                                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
                                              ),
                                            ],
                                          );
                                        }
                                        return
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 16, color: Colors.red),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  snapshot.data ?? "غير معروف",
                                                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );

                                      },
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    final pageContext = context;

                                    final fields = [
                                      generic_modal.FormFieldConfig(
                                        key: "name",
                                        hint: "اسم الموظف",
                                        icon: const Icon(Icons.person, color: Colors.grey),
                                        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
                                      ),
                                      generic_modal.FormFieldConfig(
                                        key: "email",
                                        hint: "البريد الإلكتروني",
                                        icon: const Icon(Icons.email, color: Colors.grey),
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return "الرجاء إدخال البريد الإلكتروني";
                                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return "البريد الإلكتروني غير صالح";
                                          return null;
                                        },
                                      ),
                                      generic_modal.FormFieldConfig(
                                        key: "phone",
                                        hint: "رقم الموظف",
                                        icon: const Icon(Icons.phone, color: Colors.grey),
                                        keyboardType: TextInputType.phone,
                                        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال رقم الموظف" : null,
                                      ),
                                      generic_modal.FormFieldConfig(
                                        key: "profession",
                                        hint: "المهنة",
                                        icon: const Icon(Icons.category, color: Colors.grey),
                                        options: ["فني كهرباء", "فني سباكة", "عامل", "مساعد", "فني"],
                                        validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار نوع المهنة" : null,
                                      ),
                                      generic_modal.FormFieldConfig(
                                        key: "location",
                                        hint: "موقع الموظف",
                                        icon: const Icon(Icons.location_on, color: Colors.red),
                                      ),
                                    ];

                                    // Controllers pour pré-remplir le formulaire
                                    final controllers = {for (var f in fields) f.key: TextEditingController()};
                                    controllers["name"]!.text = employee.firstName ?? "";
                                    controllers["email"]!.text = employee.email ?? "";
                                    controllers["phone"]!.text = employee.phone ?? "";
                                    controllers["profession"]!.text = employee.profession ?? "";
                                    String locationText = "";

                                    if (employee.latitude != null && employee.longitude != null) {
                                      getAddressFromLatLng(employee.latitude!, employee.longitude!)
                                          .then((address) {
                                        controllers["location"]!.text = address;
                                      });
                                    }
                                    controllers["location"]!.text = locationText;

                                    double? selectedLat = employee.latitude;
                                    double? selectedLng = employee.longitude;

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return generic_modal.GenericFormModal(
                                          title: "تعديل الموظف",
                                          submitButtonText: "حفظ",
                                          fields: fields,
                                          controllers: controllers,
                                          onSubmit: (values) async {
                                            final updatedEmployee = Employees(
                                              id: employee.id,
                                              firstName: values["name"],
                                              email: values["email"],
                                              phone: values["phone"],
                                              profession: values["profession"],
                                              latitude: selectedLat,
                                              longitude: selectedLng,
                                            );

                                            final result = await sl<UpdateEmployeeUseCase>().call(
                                              params: {'id': updatedEmployee.id!, 'employee': updatedEmployee},
                                            );

                                            result.fold(
                                                  (failure) {
                                                CustomSnackBar.show(
                                                  pageContext,
                                                  message: "خطأ أثناء التحديث",
                                                  type: SnackBarType.error,
                                                );
                                              },
                                                  (_) async {
                                                setState(() {
                                                  final index = employees.indexWhere((e) => e.id == employee.id);
                                                  if (index != -1) employees[index] = updatedEmployee;
                                                });

                                                CustomSnackBar.show(
                                                  pageContext,
                                                  message: "تم تحديث الموظف بنجاح",
                                                  type: SnackBarType.success,
                                                );

                                                await _sendNotification(
                                                  title: "تعديل موظف",
                                                  message: "تم تعديل بيانات الموظف: ${updatedEmployee.firstName}",
                                                  route: "/home",
                                                  userId: updatedEmployee.id,
                                                );

                                                Navigator.of(context).pop();
                                              },
                                            );
                                          },
                                          extraFieldBuilders: {
                                            "location": (field, controller) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 15),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    final result = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => const SelectLocationMap(),
                                                      ),
                                                    );

                                                    if (result != null && result is Map) {
                                                      selectedLat = (result["lat"] as num).toDouble();
                                                      selectedLng = (result["lng"] as num).toDouble();
                                                      controller.text = result["address"] ?? "العنوان غير متوفر";
                                                    }
                                                  },
                                                  child: AbsorbPointer(
                                                    child: NewRoundTextField(
                                                      hintText: field.hint,
                                                      controller: controller,
                                                      right: const Icon(Icons.location_on, color: Colors.red),
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          },

                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final confirm = await CustomDialog.show(
                                      context,
                                      title: "تأكيد الحذف",
                                      message:
                                      "هل أنت متأكد أنك تريد حذف هذا الموظف؟",
                                      type: DialogType.confirm,
                                      confirmText: "حذف",
                                      cancelText: "إلغاء",
                                    );

                                    if (confirm == true) {
                                      await _deleteEmployee(employee.id!);
                                    }
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddEmployeeModal(
                title: "إضافة موظف جديد",
                submitButtonText: "إضافة",
                projectId: "null",
                onAdd: (values) {
                  setState(() {
                    employees.add(
                      Employees(
                        id: values["id"],
                        firstName: values["firstName"],
                        email: values["email"],
                        phone: values["phone"],
                        profession: values["profession"],
                        latitude: values["latitude"],
                        longitude: values["longitude"],
                        projectId: null,
                      ),
                    );
                  });
                },
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          selectedType: widget.selectedType,
        ),
      ),
    );
  }
}

