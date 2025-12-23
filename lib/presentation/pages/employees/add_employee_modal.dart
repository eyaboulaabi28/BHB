import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../service_locator.dart';

class AddEmployeeModal extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;
  final String title;
  final String submitButtonText;
  final String? projectId; // si vous voulez lier l'employé à un projet

  const AddEmployeeModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة موظف جديد",
    this.submitButtonText = "إضافة",
    this.projectId,
  });

  @override
  State<AddEmployeeModal> createState() => _AddEmployeeModalState();
}

class _AddEmployeeModalState extends State<AddEmployeeModal> {
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

    fields = [
      FormFieldConfig(
        key: "name",
        hint: "اسم الموظف",
        icon: const Icon(Icons.person, color: Colors.grey),
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
      ),
      FormFieldConfig(
        key: "email",
        hint: "البريد الإلكتروني",
        icon: const Icon(Icons.email, color: Colors.grey),
        keyboardType: TextInputType.emailAddress,

      ),
      FormFieldConfig(
        key: "phone",
        hint: "رقم الموظف",
        icon: const Icon(Icons.phone, color: Colors.grey),
        keyboardType: TextInputType.phone,
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال رقم الموظف" : null,
      ),
      FormFieldConfig(
        key: "profession",
        hint: "مهنة الموظف",
        icon: const Icon(Icons.category, color: Colors.grey),
        options: ["فني كهرباء", "فني سباكة", "عامل", "مساعد", "فني"],
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار المهنة الموظف" : null,
      ),
      FormFieldConfig(
        key: "location",
        hint: "موقع الموظف",
        icon: const Icon(Icons.location_on, color: Colors.red),
      ),
    ];

    _controllers = {for (var f in fields) f.key: TextEditingController()};
    _obscureMap = {for (var f in fields) f.key: f.isPassword};
  }

  Future<void> _sendNotification({
    required String title,
    required String message,
    String? userId,
    String? route,
  }) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      userId: userId,
      route: route,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _createNotificationUseCase(notification: notif);
  }

  @override
  Widget build(BuildContext context) {
    final fields = <FormFieldConfig>[
      FormFieldConfig(
        key: "name",
        hint: "اسم الموظف",
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
        hint: "رقم الموظف",
        icon: const Icon(Icons.phone, color: Colors.grey),
        keyboardType: TextInputType.phone,
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال رقم الموظف" : null,
      ),
      FormFieldConfig(
        key: "profession",
        hint: "مهنة الموظف",
        icon: const Icon(Icons.category, color: Colors.grey),
        options: ["فني كهرباء", "فني سباكة", "عامل", "مساعد", "فني"],
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء اختيار مهنة الموظف" : null,
      ),
      FormFieldConfig(
        key: "location",
        hint: "موقع الموظف",
        icon: const Icon(Icons.location_on, color: Colors.red),
      ),
    ];

    return GenericFormModal(
      title: widget.title,
      fields: fields,

      // ---------------- LOCATION HANDLER ------------------
      extraFieldBuilders: {
        "location": (field, controller) {
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectLocationMap()),
              );

              if (result != null && result is Map) {
                // ✅ عرض اسم الموقع
                controller.text = result["address"];

                // ✅ تخزين الإحداثيات فقط
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


      // ---------------- SUBMIT LOGIC (UNCHANGED) -----------------
      onSubmit: (values) async {
        final email = values["email"].trim();

        try {


          final employe = Employees(
            firstName: values["name"].trim(),
            email: email,
            phone: values["phone"].trim(),
            profession: values["profession"].trim(),
            role: "employee",
            projectId: widget.projectId,
            latitude: selectedLat,
            longitude: selectedLng,
          );

          final addEmployeeUseCase = sl<AddEmployeeUseCase>();
          final result = await addEmployeeUseCase.call(params: employe);

          result.fold(
                (failure) {
              CustomSnackBar.show(
                context,
                message: "حدث خطأ أثناء إضافة الموظف. الرجاء المحاولة مرة أخرى.",
                type: SnackBarType.error,
              );
            },
                (success) async {
              CustomSnackBar.show(
                context,
                message: "تمت إضافة الموظف بنجاح.",
                type: SnackBarType.success,
              );

              await _sendNotification(
                title: "موظف جديد",
                message: "تم إضافة موظف جديد: ${values["name"].trim()}",
                userId: success,
                route: "/home",
              );

              widget.onAdd({
                "id": success,
                "firstName": values["name"].trim(),
                "email": values["email"].trim(),
                "phone": values["phone"].trim(),
                "profession": values["profession"].trim(),
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

