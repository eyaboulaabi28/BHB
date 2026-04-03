
import 'dart:io';
import 'dart:typed_data';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:app_bhb/domain/auth/usecases/materials_usecases.dart';
import '../../../service_locator.dart';

class FormFieldConfig {
  final String key;
  final String hint;
  final Widget? icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<String>? options;

  FormFieldConfig({
    required this.key,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.options,
  });
}

class AddMateriaModal extends StatefulWidget {
  final Function(Map<String, String> values) onAdd;
  final String title;
  final String submitButtonText;
  final String projectId;

  const AddMateriaModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة مادة جديدة",
    this.submitButtonText = "إضافة",
    required this.projectId,
  });

  @override
  State<AddMateriaModal> createState() => _AddMateriaModalState();
}

class _AddMateriaModalState extends State<AddMateriaModal> {
  final _formKey = GlobalKey<FormState>();
  late final CreateNotificationUseCase _createNotificationUseCase;
  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;
  late String? currentUserId;

  List<Engineer> engineers = [];
  late final TextEditingController engineerCtrl;
  String? selectedEngineerId;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadEngineers();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;

    engineerCtrl = TextEditingController();

    fields = [
      FormFieldConfig(
        key: "stage",
        hint: "مرحلة البناء",
        options: ["عظم", "ميدة", "سقف", "احواش","التشغيل والتسليم"],
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

    _controllers = {for (var f in fields) f.key: TextEditingController()};
    _obscureMap = {for (var f in fields) f.key: f.isPassword};
  }

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold(
          (e) => debugPrint("Error engineers: $e"),
          (list) => setState(() => engineers = List<Engineer>.from(list)),
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
                    enableSearch:true,
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
                  if (field.key == "description") return Padding(padding: const EdgeInsets.only(bottom: 15), child: _buildParagraphField(field));

                  // Si le champ a des options → SelectField
                  if (field.options != null && field.options!.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: NewRoundSelectField(
                        hintText: field.hint,
                        options: field.options!,
                        controller: _controllers[field.key],
                        validator: field.validator,
                        rightIcon: field.icon,
                        enableSearch: true, // si tu veux la recherche
                        onChanged: (value) {
                          // Assure que le controller contient bien la valeur choisie
                          _controllers[field.key]!.text = value ?? "";
                        },
                      ),
                    );
                  }

                  // Sinon → TextField classique
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
                        onPressed: () {
                          if (mounted) Navigator.pop(context);
                        },
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
                            try {
                              final material = Materials(
                                stage: _controllers["stage"]!.text.trim(),
                                unit: _controllers["unit"]!.text.trim(),
                                description: _controllers["description"]!.text.trim(),
                                engineerId: selectedEngineerId,
                                projectId: widget.projectId,
                              );

                              final addMaterialUseCase =
                              sl<AddMaterialUseCase>();
                              final result =
                              await addMaterialUseCase.call(params: material);

                              if (!mounted) return;

                              result.fold(
                                    (failure) {
                                  CustomSnackBar.show(
                                    context,
                                    message: "حدث خطأ أثناء إضافة المادة.",
                                    type: SnackBarType.error,
                                  );
                                },
                                    (id) {
                                  final newMaterial = Materials(
                                    id: id,
                                    stage: material.stage,
                                    unit: material.unit,
                                    description: material.description,
                                    engineerId: material.engineerId,
                                    projectId: material.projectId,
                                  );

                                  CustomSnackBar.show(
                                    context,
                                    message: "تمت إضافة المادة بنجاح ✅",
                                    type: SnackBarType.success,
                                  );

                                  _sendNotification(
                                    title: "مادة جديدة",
                                    message: "تم إضافة مادة جديدة: المرحلة: ${newMaterial.stage}, الوصف: ${newMaterial.description}",
                                    userId: currentUserId,
                                    route: null,
                                  );

                                  final engineerName = engineers
                                      .firstWhere((e) => e.id == selectedEngineerId)
                                      .firstName;
                                  widget.onAdd({
                                    "id": newMaterial.id ?? "",
                                    "stage": newMaterial.stage ?? "",
                                    "unit": newMaterial.unit ?? "",
                                    "description": newMaterial.description ?? "",
                                    "engineerId": newMaterial.engineerId ?? "",
                                    "engineerName": engineerName ?? "",
                                  });

                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              if (mounted) {
                                CustomSnackBar.show(
                                  context,
                                  message:
                                  "حدث خطأ غير متوقع: ${e.toString()}",
                                  type: SnackBarType.error,
                                );
                              }
                            }
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
                )
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


