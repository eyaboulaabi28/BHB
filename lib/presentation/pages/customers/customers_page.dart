import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/customers/add_customer_modal.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal; // supprime ou alias l'autre import si nécessaire
import 'package:geocoding/geocoding.dart';
import '../../../data/auth/models/customers_model.dart';
import '../../../service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class CustomersPage extends StatefulWidget {
  final String selectedType;

  const CustomersPage({super.key, required this.selectedType});


  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  int _selectedIndex = 0;
  late final GetCustomerUseCase _getAllCustomerUseCase;
  late final DeleteCustomerUseCase _deleteCustomerUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;

  List<Customers> customers = [];
  List<Customers> filteredCustomers = [];

  final TextEditingController _searchController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _getAllCustomerUseCase = sl<GetCustomerUseCase>();
    _deleteCustomerUseCase = sl<DeleteCustomerUseCase>();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _fetchCustomers();
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

  Future<void>  _fetchCustomers() async {
    final result = await _getAllCustomerUseCase.call();

    result.fold(
          (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $failure")),
        );
      },
          (customersList) {
        setState(() {
          customers = List<Customers>.from(customersList);
          filteredCustomers = customers;
        });
      },
    );
  }
  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers
            .where((e) =>
        (e.firstName ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.email ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.role ?? "").toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _deleteCustomers(String customerId) async {
    final result = await _deleteCustomerUseCase.call(params: customerId);
    final deletedCustomer =
    customers.firstWhere((e) => e.id == customerId, orElse: () => Customers());
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
          customers.removeWhere((e) => e.id == customerId);
        });

        CustomSnackBar.show(
          context,
          message: "تم حذف العميل بنجاح",
          type: SnackBarType.success,
        );
         _sendNotification(
        title: "حذف عميل",
        message: "تم حذف العميل: ${deletedCustomer.firstName ?? ""}",
        route: "/home",
        userId: customerId,
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

      if (locality.isEmpty && street.isEmpty && country.isEmpty) {
        return "غير معروف";
      }

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
                  "إدارة العملاء",
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
              hintText: 'ابحث عن عميل...',
              onChanged: _filterCustomers,
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
              child: filteredCustomers.isEmpty
                  ? const Center(
                child: Text(
                  "لا يوجد عملاء مطابقون للبحث",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
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
                              child: Icon(Icons.person,
                                  color: TColor.primary),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      const SizedBox(height: 20),
                                      Text(
                                        customer.firstName ?? "",
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.email, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          customer.email ?? "",
                                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis, // tronque si trop long
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          customer.phone ?? "",
                                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  if (customer.latitude != null && customer.longitude != null)
                                    FutureBuilder<String>(
                                      future: getAddressFromLatLng(customer.latitude!, customer.longitude!),
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
                                  onPressed: () async{
                                    final pageContext = context;

                                    final fields = [
                                      generic_modal.FormFieldConfig(
                                        key: "name",
                                        hint: "اسم العميل",
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
                                        hint: "رقم العميل",
                                        icon: const Icon(Icons.phone, color: Colors.grey),
                                        keyboardType: TextInputType.phone,
                                        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال رقم العميل" : null,
                                      ),
                                      generic_modal.FormFieldConfig(
                                        key: "type",
                                        hint: "نوع العميل",
                                        icon: const Icon(Icons.category, color: Colors.grey),
                                        options: ["فردي", "شركة"],
                                        validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار نوع العميل" : null,
                                      ),
                                      generic_modal.FormFieldConfig(
                                        key: "location",
                                        hint: "موقع العميل",
                                        icon: const Icon(Icons.location_on, color: Colors.red),
                                      ),
                                    ];
                                    String locationText = "";
                                    final controllers = {for (var f in fields) f.key: TextEditingController()};
                                    controllers["name"]!.text = customer.firstName ?? "";
                                    controllers["email"]!.text = customer.email ?? "";
                                    controllers["phone"]!.text = customer.phone ?? "";
                                    controllers["type"]!.text = customer.type ?? "";

                                    if (customer.latitude != null && customer.longitude != null) {
                                      locationText = await getAddressFromLatLng(
                                        customer.latitude!,
                                        customer.longitude!,
                                      );
                                    }

                                    controllers["location"]!.text = locationText;


                                    double? selectedLat = customer.latitude;
                                    double? selectedLng = customer.longitude;

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return generic_modal.GenericFormModal(
                                          title: "تعديل العميل",
                                          submitButtonText: "حفظ",
                                          fields: fields,
                                          controllers: controllers, // ajouter si GenericFormModal accepte des controllers
                                          onSubmit: (values) async {
                                            final updatedCustomer = Customers(
                                              id: customer.id,
                                              firstName: values["name"],
                                              email: values["email"],
                                              type: values["type"],
                                              phone: values["phone"],
                                              latitude: selectedLat,
                                              longitude: selectedLng,
                                            );

                                            final result = await sl<UpdateCustomerUseCase>().call(
                                              params: {
                                                'id': updatedCustomer.id!,
                                                'customer': updatedCustomer,
                                              },
                                            );

                                            result.fold(
                                                  (failure) {
                                                CustomSnackBar.show(
                                                  pageContext,
                                                  message: "خطأ أثناء التحديث",
                                                  type: SnackBarType.error,
                                                );
                                              },
                                                  (_) {
                                                setState(() {
                                                  final index = customers.indexWhere((e) => e.id == customer.id);
                                                  if (index != -1) customers[index] = updatedCustomer;
                                                });

                                                CustomSnackBar.show(
                                                  pageContext,
                                                  message: "تم تحديث العميل بنجاح",
                                                  type: SnackBarType.success,
                                                );

                                                _sendNotification(
                                                  title: "تحديث بيانات عميل",
                                                  message: "تم تعديل بيانات العميل: ${values["name"]}",
                                                  route: "/home",
                                                  userId: customer.id,
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
                                                      MaterialPageRoute(builder: (_) => const SelectLocationMap()),
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
                                      message: "هل أنت متأكد أنك تريد حذف هذا العميل؟",
                                      type: DialogType.confirm,
                                      confirmText: "حذف",
                                      cancelText: "إلغاء",
                                    );

                                    if (confirm == true) {
                                      await _deleteCustomers(customer.id!);
                                    }
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),


                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

              ),
            )

          ],
        ),

        /******************/
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddCustomerModal(
                title: "إضافة عميل جديد",
                submitButtonText: "إضافة",
                onAdd: (values) {
                  setState(() {
                    customers.add(
                         Customers(
                           id: values["id"],
                           firstName:values["name"],
                          email:values["email"] ,
                          type:values["type"],
                          phone:values["phone"],
                           latitude: values["latitude"],
                           longitude: values["longitude"],
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
