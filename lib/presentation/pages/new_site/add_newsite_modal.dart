import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_newsite.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/auth/usecases/uses_cases_customers.dart';
import '../../../service_locator.dart';


class AddNewsiteModal extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;

  final String title;
  final String submitButtonText;
  final BuildContext parentContext;

  const AddNewsiteModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة زيارة موقع جديد",
    this.submitButtonText = "إضافة",
    required this.parentContext,
  });

  @override
  State<AddNewsiteModal> createState() => _AddNewsiteModalState();
}

class _AddNewsiteModalState extends State<AddNewsiteModal> {
  final _formKey = GlobalKey<FormState>();
  late final CreateNotificationUseCase _createNotificationUseCase;
  late String? currentUserId;

  // Champs dynamiques pour ce formulaire
  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;
  double? selectedLat;
  double? selectedLng;
  DateTime? selectedDate;
  List<Engineer> engineers = [];
  final TextEditingController engineerCtrl = TextEditingController();
  String? selectedEngineerId;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadEngineers();
    final fields = <FormFieldConfig>[

      FormFieldConfig(
        key: "customerName",
        hint: "اسم العميل",
        icon: const Icon(Icons.person, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
      ),
      FormFieldConfig(
        key: "projectName",
        hint: "اسم المشروع",
        icon: const Icon(Icons.edit_note, color: Colors.grey),
      ),
      FormFieldConfig(
        key: "phone",
        hint: "رقم العميل",
        icon: const Icon(Icons.phone, color: Colors.grey),
        keyboardType: TextInputType.phone,
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال رقم العميل" : null,
      ),
      FormFieldConfig(
        key: "location",
        hint: "موقع العميل",
        icon: const Icon(Icons.location_on, color: Colors.red),
      ),
      FormFieldConfig(
        key: "visitDate",
        hint: "تاريخ الزيارة",
        icon: const Icon(Icons.date_range_outlined, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال تاريخ الزيارة" : null,
      ),
      FormFieldConfig(
        key: "engineer",
        hint: "اختيار المهندس",
      ),

    ];
    _controllers = {for (var f in fields) f.key: TextEditingController()};
    _obscureMap = {for (var f in fields) f.key: f.isPassword};
    currentUserId = FirebaseAuth.instance.currentUser?.uid;

  }

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold(
          (e) => debugPrint("Error engineers"),
          (list) => setState(() {
        engineers = List<Engineer>.from(list);
      }),
    );
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


  @override
  Widget build(BuildContext context) {
    final fields = <FormFieldConfig>[

      FormFieldConfig(
        key: "customerName",
        hint: "اسم العميل",
        icon: const Icon(Icons.person, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
      ),
      FormFieldConfig(
        key: "projectName",
        hint: "اسم المشروع",
        icon: const Icon(Icons.edit_note, color: Colors.grey),
      ),
      FormFieldConfig(
        key: "phone",
        hint: "رقم العميل",
        icon: const Icon(Icons.phone, color: Colors.grey),
        keyboardType: TextInputType.phone,
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال رقم العميل" : null,
      ),
      FormFieldConfig(
        key: "location",
        hint: "موقع العميل",
        icon: const Icon(Icons.location_on, color: Colors.red),
      ),
      FormFieldConfig(
        key: "createdAt",
        hint: "تاريخ الزيارة",
        icon: const Icon(Icons.date_range_outlined, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال تاريخ الزيارة" : null,
      ),
      FormFieldConfig(
        key: "engineer",
        hint: "اختيار المهندس",
      ),

    ];

    return GenericFormModal(
      title: widget.title,
      fields: fields,

      // --------------- LOCATION HANDLER -----------------
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

                if (result != null && result is Map<String, dynamic>) {
                  selectedLat = result["lat"];
                  selectedLng = result["lng"];
                  controller.text = result["address"] ??
                      "Lat: $selectedLat, Lng: $selectedLng";
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


        // 🟢 DATE PICKER
        "createdAt": (field, controller) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: NewRoundTextField(
              hintText: field.hint,
              controller: controller,
              readOnly: true,
              right: const Icon(Icons.date_range_outlined, color: Colors.grey),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  locale: const Locale('ar', 'AE'),
                  builder: (context, child) {
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: child!,
                    );
                  },
                );

                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                    controller.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),
          );
        },


        // 🟢 ENGINEER SELECT (المهم)
        "engineer": (_, __) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: NewRoundSelectField(
              hintText: "اختيار المهندس",
              enableSearch: true,
              options: engineers.map((e) => e.firstName ?? "").toList(),
              controller: engineerCtrl,
              rightIcon: const Icon(Icons.engineering),
              onChanged: (value) {
                final engineer =
                engineers.firstWhere((e) => e.firstName == value);
                selectedEngineerId = engineer.id;
              },
            ),
          );
        },

      },



      // ---------------- SUBMIT LOGIC (UNCHANGED!) ------------------
      onSubmit: (values) async {
        try {
          // Créer le client à ajouter
          final newVisit = NewSite(
            customerName: values["customerName"],
            projectName: values["projectName"],
            phone: values["phone"],
            nameEngineer: engineerCtrl.text.trim(),
            uidEngineer: selectedEngineerId,
            latitude: selectedLat ,
            longitude: selectedLng ,
            createdAt:  selectedDate,
            task: SiteTask(items: []),
          );

          // Appel du use case pour ajouter le client
          final addCustomerUseCase = sl<AddNewSiteUseCase>();
          final result = await addCustomerUseCase.call(params: newVisit);

          result.fold(
                (failure) {
              // En cas d'erreur, afficher le SnackBar **après la fermeture du modal**
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                CustomSnackBar.show(
                  widget.parentContext,
                  message:  failure.toString(),
                  type: SnackBarType.error,
                );
              });
            },
                (success) async {
              // Fermeture du modal
              Navigator.pop(context);

              // Ajouter le client à la liste dans la page parent
              widget.onAdd({
                "id": success,
                "customerName": values["customerName"]?.trim() ?? "",
                "projectName": values["projectName"]?.trim() ?? "",
                "phone": values["phone"]?.trim() ?? "",
                "uidEngineer": selectedEngineerId ?? "",
                "nameEngineer": engineerCtrl.text.trim(),
                "latitude": selectedLat,
                "longitude": selectedLng,
                "createdAt": selectedDate,
              });

              // Afficher le SnackBar **après un petit délai**
              Future.delayed(const Duration(milliseconds: 200), () {
                CustomSnackBar.show(
                  widget.parentContext,
                  message: "تمت إضافة زيارة موقع جديد بنجاح.",
                  type: SnackBarType.success,
                );
              });

              // Envoyer la notification
              await _sendNotification(
                title: "زيارة موقع جديد",
                message: "تم إضافة زيارة موقع جديد للعميل : ${values["customerName"].trim()}",
                route: "/home",
                userId: currentUserId,
              );
            },
          );
        } catch (e) {
          // En cas d'exception, fermer le modal et afficher le SnackBar
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 200), () {
            CustomSnackBar.show(
              widget.parentContext,
              message: "حدث خطأ غير متوقع: ${e.toString()}",
              type: SnackBarType.error,
            );
          });
        }
      },

    );
  }
}




