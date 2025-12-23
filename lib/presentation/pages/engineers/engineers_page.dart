import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:app_bhb/presentation/pages/engineers/add_engineer_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal; // supprime ou alias l'autre import si nécessaire
import 'package:geocoding/geocoding.dart';

import '../../../service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EngineersPage extends StatefulWidget {
  final String selectedType;

  const EngineersPage({super.key, required this.selectedType});

  @override
  State<EngineersPage> createState() => _EngineersPageState();
}

class _EngineersPageState extends State<EngineersPage> {
  int _selectedIndex = 0;
  late final GetEngineersUseCase _getAllEngineersUseCase;
  late final DeleteEngineerUseCase _deleteEngineerUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;

  List<Engineer> engineers = [];
  List<Engineer> filteredEngineers = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getAllEngineersUseCase = sl<GetEngineersUseCase>();
    _deleteEngineerUseCase = sl<DeleteEngineerUseCase>();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _fetchEngineers();
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

  Future<void> _fetchEngineers() async {
    final result = await _getAllEngineersUseCase.call();

    result.fold(
          (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $failure")),
        );
      },
          (engineersList) {
        setState(() {
          engineers = List<Engineer>.from(engineersList);
          filteredEngineers = engineers;
        });
      },
    );
  }

  void _filterEngineers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredEngineers = engineers;
      } else {
        filteredEngineers = engineers.where((e) {
          final phone = e.phone ?? "";
          final role = e.role ?? "";
          return (e.firstName ?? "").toLowerCase().contains(query.toLowerCase()) ||
              (e.email ?? "").toLowerCase().contains(query.toLowerCase()) ||
              role.toLowerCase().contains(query.toLowerCase()) ||
              phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteEngineer(String engineerId) async {
    final result = await _deleteEngineerUseCase.call(params: engineerId);
    final deletedEngineer =
    engineers.firstWhere((e) => e.id == engineerId, orElse: () => Engineer());

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "خطأ  في الحذف  : $failure",
          type: SnackBarType.error,
        );
      },
          (_) {
        setState(() {
          engineers.removeWhere((e) => e.id == engineerId);
        });

        CustomSnackBar.show(
          context,
          message: "تم حذف المهندس بنجاح",
          type: SnackBarType.success,
        );

        _sendNotification(
          title: "حذف مهندس",
          message: "تم حذف المهندس: ${deletedEngineer.firstName ?? ""}",
          route: "/engineers",
          userId: engineerId,
        );
      },
    );
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
      if (locality.isEmpty && street.isEmpty && country.isEmpty) return "غير معروف";
      return "$locality - $street - $country".trim();
    } catch (e) {
      print("Reverse Geocoding Error: $e");
      return "غير معروف";
    }
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
                  "إدارة المهندسين",
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
              hintText: 'ابحث عن مهندس...',
              onChanged: _filterEngineers,
              onFilterTap: () {
                CustomSnackBar.show(
                  context,
                  message: "ميزة الفلترة قيد التطوير ",
                  type: SnackBarType.info,
                );
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredEngineers.isEmpty
                  ? const Center(
                child: Text(
                  "لا يوجد مهندسون مطابقون للبحث",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredEngineers.length,
                itemBuilder: (context, index) {
                  final engineer = filteredEngineers[index];
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
                            child: Icon(Icons.engineering, color: TColor.primary),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        engineer.firstName ?? "",
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  ],
                                ),

                                const SizedBox(height: 5),
                                if (engineer.email != null && engineer.email!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.email, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          engineer.email!,
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 5),
                                if (engineer.phone != null && engineer.phone!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(
                                        engineer.phone!,
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],

                                  ),
                                const SizedBox(height: 5),
                                if (engineer.latitude != null && engineer.longitude != null)
                                  FutureBuilder<String>(
                                    future: getAddressFromLatLng(
                                        engineer.latitude!, engineer.longitude!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Row(
                                          children: const [
                                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                                            SizedBox(width: 5),
                                            Text(
                                              "جاري جلب الموقع...",
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.red),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              snapshot.data ?? "غير معروف",
                                              style: const TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                const SizedBox(height: 15),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Chip(
                                    avatar: Icon(
                                      engineer.status == "approved"
                                          ? Icons.check_circle
                                          : Icons.hourglass_bottom,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: Text(
                                      engineer.status == "approved"
                                          ? "مقبول"
                                          : "قيد المراجعة",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Tajawal',
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: engineer.status == "approved"
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),

                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  final fields = [
                                    generic_modal.FormFieldConfig(
                                      key: "name",
                                      hint: "اسم المهندس",
                                      icon: const Icon(Icons.person, color: Colors.grey),
                                      validator: (v) =>
                                      (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
                                    ),
                                    generic_modal.FormFieldConfig(
                                      key: "email",
                                      hint: "البريد الإلكتروني",
                                      icon: const Icon(Icons.email, color: Colors.grey),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return "الرجاء إدخال البريد الإلكتروني";
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                                          return "البريد الإلكتروني غير صالح";
                                        return null;
                                      },
                                    ),
                                    generic_modal.FormFieldConfig(
                                      key: "phone",
                                      hint: "رقم الهاتف",
                                      icon: const Icon(Icons.phone, color: Colors.grey),
                                      keyboardType: TextInputType.phone,
                                      validator: (v) =>
                                      (v == null || v.isEmpty) ? "الرجاء إدخال رقم الهاتف" : null,
                                    ),

                                    generic_modal.FormFieldConfig(
                                      key: "location",
                                      hint: "موقع المهندس",
                                      icon: const Icon(Icons.location_on, color: Colors.red),
                                    ),
                                  ];
                                  String locationText = "";
                                  final controllers = {for (var f in fields) f.key: TextEditingController()};
                                  controllers["name"]!.text = engineer.firstName ?? "";
                                  controllers["email"]!.text = engineer.email ?? "";
                                  controllers["phone"]!.text = engineer.phone ?? "";

                                  if (engineer.latitude != null && engineer.longitude != null) {
                                    getAddressFromLatLng(engineer.latitude!, engineer.longitude!)
                                        .then((address) {
                                      controllers["location"]!.text = address;
                                    });
                                  }
                                  controllers["location"]!.text = locationText;

                                  double? selectedLat = engineer.latitude;
                                  double? selectedLng = engineer.longitude;

                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) {
                                      return generic_modal.GenericFormModal(
                                        title: "تعديل المهندس",
                                        submitButtonText: "حفظ",
                                        fields: fields,
                                        controllers: controllers,
                                        onSubmit: (values) async {
                                          final updatedEngineer = Engineer(
                                            id: engineer.id,
                                            firstName: values["name"],
                                            email: values["email"],
                                            phone: values["phone"],
                                            latitude: selectedLat,
                                            longitude: selectedLng,
                                          );

                                          final result = await sl<UpdateEngineerUseCase>().call(
                                            params: {
                                              'id': updatedEngineer.id!,
                                              'engineer': updatedEngineer,
                                            },
                                          );

                                          result.fold(
                                                (failure) {
                                              CustomSnackBar.show(
                                                context,
                                                message: "خطأ أثناء التحديث",
                                                type: SnackBarType.error,
                                              );
                                            },
                                                (_) {
                                              setState(() {
                                                final index = engineers.indexWhere((e) => e.id == engineer.id);
                                                if (index != -1) engineers[index] = updatedEngineer;
                                              });

                                              CustomSnackBar.show(
                                                context,
                                                message: "تم تحديث المهندس بنجاح",
                                                type: SnackBarType.success,
                                              );

                                              _sendNotification(
                                                title: "تعديل مهندس",
                                                message:
                                                "تم تعديل بيانات المهندس: ${updatedEngineer.firstName}",
                                                route: "/engineers",
                                                userId: engineer.id,
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
                                                  }                                                },
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
                                    message: "هل أنت متأكد أنك تريد حذف هذا المهندس؟",
                                    type: DialogType.confirm,
                                    confirmText: "حذف",
                                    cancelText: "إلغاء",
                                  );
                                  if (confirm == true) {
                                    await _deleteEngineer(engineer.id!);
                                  }
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                              IconButton(
                                icon: Icon(
                                  engineer.status == "approved"
                                      ? Icons.verified
                                      : Icons.hourglass_bottom,
                                  color: engineer.status == "approved"
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                onPressed: () async {
                                  if (engineer.status == "approved") return;

                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(engineer.id)
                                      .update({'status': 'approved'});

                                  setState(() {
                                    engineer.status = "approved";
                                  });

                                  CustomSnackBar.show(
                                    context,
                                    message: "تمت الموافقة على المهندس",
                                    type: SnackBarType.success,
                                  );
                                },
                              ),

                            ],
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddEngineerModal(
                title: "إضافة مهندس جديد",
                submitButtonText: "إضافة",
                onAdd: (values) {
                  setState(() {
                    engineers.add(
                      Engineer(
                        id: values["id"],
                        firstName: values["name"],
                        email: values["email"],
                        phone: values["phone"],
                        role: values["role"] ?? "مهندس",
                        latitude: values["latitude"],
                        longitude: values["longitude"],
                      ),
                    );
                  });
                  _sendNotification(
                    title: "إضافة مهندس",
                    message: "تم إضافة مهندس جديد: ${values["name"]}",
                    route: "/engineers",
                  );
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
