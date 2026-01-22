
import 'dart:io';
import 'dart:typed_data';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:flutter/material.dart';

import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:app_bhb/domain/auth/usecases/materials_usecases.dart';
import '../../../service_locator.dart';

class EditMateriaModal extends StatefulWidget {
  final Materials material;
  final Function(Map<String, String>) onEdit;
  final String title;
  final String submitButtonText;

  const EditMateriaModal({
    super.key,
    required this.material,
    required this.onEdit,
    this.title = "تعديل المادة",
    this.submitButtonText = "حفظ",
  });

  @override
  State<EditMateriaModal> createState() => _EditMateriaModalState();
}

class _EditMateriaModalState extends State<EditMateriaModal> {
  final _formKey = GlobalKey<FormState>();
  late final CreateNotificationUseCase _createNotificationUseCase;
  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;

  List<Engineer> engineers = [];
  late final TextEditingController engineerCtrl;
  String? selectedEngineerId;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadEngineers();

    engineerCtrl = TextEditingController();

    // Champs dynamiques comme AddMateriaModal
    fields = [
      FormFieldConfig(
        key: "stage",
        hint: "مرحلة البناء",
        options: ["عظم", "ميدة", "سقف", "احواش"],
      ),
      FormFieldConfig(
        key: "unit",
        hint: "نوع المواد",
        options: ["كهرباء", "سباكة"],
      ),
      FormFieldConfig(
        key: "description",
        hint: "تفاصيل المواد",
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال تفاصيل المواد" : null,
      ),
    ];

    // Initialisation des controllers avec les valeurs existantes
    _controllers = {
      for (var f in fields)
        f.key: TextEditingController(
            text: _getFieldValue(widget.material, f.key) ?? "")
    };
    _obscureMap = {for (var f in fields) f.key: f.isPassword};

    // Engineer
    selectedEngineerId = widget.material.engineerId;
  }

  String? _getFieldValue(Materials material, String key) {
    switch (key) {
      case "stage":
        return material.stage;
      case "unit":
        return material.unit;
      case "description":
        return material.description;
    }
    return null;
  }

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold(
          (e) => debugPrint("Error engineers: $e"),
          (list) {
        setState(() {
          engineers = List<Engineer>.from(list);
          // Initialiser engineerCtrl avec le nom actuel
          final currentEng = engineers.firstWhere(
                  (e) => e.id == selectedEngineerId,
              orElse: () => Engineer(id: "", firstName: ""));
          engineerCtrl.text = currentEng.firstName ?? "";
        });
      },
    );
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          constraints: const BoxConstraints(minHeight: 500),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )),
                const SizedBox(height: 20),

                // Sélecteur ingénieur
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: NewRoundSelectField(
                    hintText: "اختيار المهندس",
                    options: engineers.map((e) => e.firstName ?? "").toList(),
                    controller: engineerCtrl,
                    enableSearch: true,
                    rightIcon: const Icon(Icons.engineering),
                    onChanged: (value) {
                      final engineer =
                      engineers.firstWhere((e) => e.firstName == value);
                      selectedEngineerId = engineer.id;
                    },
                  ),
                ),

                // Champs dynamiques
                ...fields.map((field) {
                  if (field.key == "description") {
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildParagraphField(field));
                  }

                  if (field.options != null && field.options!.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: NewRoundSelectField(
                        hintText: field.hint,
                        options: field.options!,
                        controller: _controllers[field.key],
                        validator: field.validator,
                        rightIcon: field.icon,
                        enableSearch: true,
                        onChanged: (value) {
                          _controllers[field.key]!.text = value ?? "";
                        },
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NewRoundTextField(
                      hintText: field.hint,
                      controller: _controllers[field.key],
                      keyboardType: field.keyboardType,
                      obscureText: _obscureMap[field.key]!,
                      right: field.icon,
                      validator: field.validator,
                    ),
                  );
                }),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: TColor.secondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "إلغاء",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TColor.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final updatedMaterial = Materials(
                              id: widget.material.id,
                              stage: _controllers["stage"]!.text.trim(),
                              unit: _controllers["unit"]!.text.trim(),
                              description: _controllers["description"]!.text.trim(),
                              engineerId: selectedEngineerId,
                              projectId: widget.material.projectId,
                            );

                            // Retourner les valeurs modifiées au parent
                            widget.onEdit({
                              "id": updatedMaterial.id ?? "",
                              "stage": updatedMaterial.stage ?? "",
                              "unit": updatedMaterial.unit ?? "",
                              "description": updatedMaterial.description ?? "",
                              "engineerId": updatedMaterial.engineerId ?? "",
                            });

                            _sendNotification(
                              title: "تعديل مادة",
                              message:
                              "تم تعديل المادة: ${updatedMaterial.stage}, ${updatedMaterial.description}",
                              userId: updatedMaterial.id,
                            );

                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          widget.submitButtonText,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParagraphField(FormFieldConfig field) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2)],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          if (field.icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: field.icon!,
            ),
          Expanded(
            child: TextFormField(
              controller: _controllers[field.key],
              maxLines: 5,
              textAlign: TextAlign.right,
              validator: field.validator,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: field.hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

