import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/auth/usecases/uses_cases_customers.dart';
import '../../../service_locator.dart';


class AddCustomerModal extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;

  final String title;
  final String submitButtonText;
  final BuildContext parentContext;

  const AddCustomerModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة عميل جديد",
    this.submitButtonText = "إضافة",
    required this.parentContext,
  });

  @override
  State<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends State<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  late final CreateNotificationUseCase _createNotificationUseCase;

  // Champs dynamiques pour ce formulaire
  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;
  double? selectedLat;
  double? selectedLng;
  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();

    final fields = <FormFieldConfig>[
      FormFieldConfig(
        key: "name",
        hint: "اسم العميل",
        icon: const Icon(Icons.person, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
      ),

      FormFieldConfig(
        key: "email",
        hint: "البريد الإلكتروني",
        icon: const Icon(Icons.email, color: Colors.grey),
        keyboardType: TextInputType.emailAddress,
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
        key: "type",
        hint: "نوع العميل",
        icon: const Icon(Icons.category, color: Colors.grey),
        options: ["فردي", "شركة"],
      ),

      FormFieldConfig(
        key: "location",
        hint: "موقع العميل",
        icon: const Icon(Icons.location_on, color: Colors.red),

      ),
    ];
    _controllers = {for (var f in fields) f.key: TextEditingController()};
    _obscureMap = {for (var f in fields) f.key: f.isPassword};
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
        key: "name",
        hint: "اسم العميل",
        icon: const Icon(Icons.person, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
      ),
      FormFieldConfig(
        key: "email",
        hint: "البريد الإلكتروني",
        icon: const Icon(Icons.email, color: Colors.grey),
        keyboardType: TextInputType.emailAddress,

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
        key: "type",
        hint: "نوع العميل",
        icon: const Icon(Icons.category, color: Colors.grey),
        options: ["فردي", "شركة"],
      ),
      FormFieldConfig(
        key: "location",
        hint: "موقع العميل",
        icon: const Icon(Icons.location_on, color: Colors.red),
      ),
    ];

    return GenericFormModal(
      title: widget.title,
      fields: fields,

      // --------------- LOCATION HANDLER -----------------
      extraFieldBuilders: {
        "location": (field, controller) {
          return GestureDetector(
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
          );
        },
      },

      // ---------------- SUBMIT LOGIC (UNCHANGED!) ------------------
      onSubmit: (values) async {
        final email = values["email"].trim();

        try {
          // Créer le client à ajouter
          final customer = Customers(
            firstName: values["name"].trim(),
            email: email,
            type: values["type"].trim(),
            phone: values["phone"].trim(),
            role: "customer",
            latitude: selectedLat,
            longitude: selectedLng,
          );

          // Appel du use case pour ajouter le client
          final addCustomerUseCase = sl<AddCustomerUseCase>();
          final result = await addCustomerUseCase.call(params: customer);

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
                "name": values["name"].trim(),
                "email": values["email"].trim(),
                "type": values["type"].trim(),
                "phone": values["phone"].trim(),
                "latitude": selectedLat,
                "longitude": selectedLng,
              });

              // Afficher le SnackBar **après un petit délai**
              Future.delayed(const Duration(milliseconds: 200), () {
                CustomSnackBar.show(
                  widget.parentContext,
                  message: "تمت إضافة العميل بنجاح.",
                  type: SnackBarType.success,
                );
              });

              // Envoyer la notification
              await _sendNotification(
                title: "عميل جديد",
                message: "تم إضافة عميل جديد: ${values["name"].trim()}",
                route: "/home",
                userId: success,
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