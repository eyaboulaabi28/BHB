import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../service_locator.dart';


class AddEngineerModal extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;
  final String title;
  final String submitButtonText;

  const AddEngineerModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة مهندس جديد",
    this.submitButtonText = "إضافة",
  });

  @override
  State<AddEngineerModal> createState() => _AddEngineerModalState();
}

class _AddEngineerModalState extends State<AddEngineerModal> {
  final _formKey = GlobalKey<FormState>();
  late final CreateNotificationUseCase _createNotificationUseCase;

  // Champs dynamiques
  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;
  double? selectedLat;
  double? selectedLng;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();

    fields = [
      FormFieldConfig(
        key: "name",
        hint: "اسم المهندس",
        icon: const Icon(Icons.person, color: Colors.grey),
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
      ),
      FormFieldConfig(
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
      FormFieldConfig(
        key: "phone",
        hint: "رقم الهاتف",
        icon: const Icon(Icons.phone, color: Colors.grey),
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.isEmpty) return "الرجاء إدخال رقم الهاتف";
          return null;
        },
      ),
      FormFieldConfig(
        key: "location",
        hint: "موقع المهندس",
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
  final List<FormFieldConfig> engineerFields = [
    FormFieldConfig(
      key: "name",
      hint: "اسم المهندس",
      icon: const Icon(Icons.person, color: Colors.grey),
      validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
    ),
    FormFieldConfig(
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
    FormFieldConfig(
      key: "phone",
      hint: "رقم الهاتف",
      icon: const Icon(Icons.phone, color: Colors.grey),
      keyboardType: TextInputType.phone,
      validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال رقم الهاتف" : null,
    ),
    FormFieldConfig(
      key: "location",
      hint: "موقع المهندس",
      icon: const Icon(Icons.location_on, color: Colors.red),
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return GenericFormModal(
      title: "إضافة مهندس جديد",
      fields: engineerFields,
      extraFieldBuilders: {
        "location": (field, controller) {
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectLocationMap()),
              );

              if (result != null && result is Map) {
                controller.text = result["address"]; // ✅ اسم الموقع

                selectedLat = result["lat"];
                selectedLng = result["lng"];
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
      onSubmit: (values) async {
        final email = values["email"].trim();

        try {


          final engineer = Engineer(
            firstName: values["name"].trim(),
            email: email,
            phone: values["phone"].trim(),
            latitude: selectedLat,
            longitude: selectedLng,
            role: "engineer",
          );

          final addEngineerUseCase = sl<AddEngineerUseCase>();
          final result = await addEngineerUseCase.call(params: engineer);

          result.fold(
                (failure) {
              CustomSnackBar.show(
                context,
                message: "حدث خطأ أثناء إضافة المهندس. الرجاء المحاولة مرة أخرى.",
                type: SnackBarType.error,
              );
            },
                (success) async {
              CustomSnackBar.show(
                context,
                message: "تمت إضافة المهندس بنجاح.",
                type: SnackBarType.success,
              );

              await _sendNotification(
                title: "مهندس جديد",
                message: "تم إضافة المهندس ${values["name"].trim()} بنجاح",
                route: "/engineers",
                userId: success,
              );

              widget.onAdd({
                "id": success,
                "name": values["name"].trim(),
                "email": email,
                "phone": values["phone"].trim(),
                "latitude": selectedLat,
                "longitude": selectedLng,
              });

              Navigator.pop(context);
            },
          );
        } catch (e) {
          CustomSnackBar.show(
            context,
            message: "حدث خطأ غير متوقع: ${e.toString()}",
            type: SnackBarType.error,
          );
        }
      },
    );
  }
}
