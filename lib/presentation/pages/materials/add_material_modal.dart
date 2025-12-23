
import 'dart:io';
import 'dart:typed_data';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
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
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  late final CreateNotificationUseCase _createNotificationUseCase;
  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();

    fields = [
      FormFieldConfig(
        key: "name",
        hint: "اسم المادة",
        icon: const Icon(Icons.label, color: Colors.grey),
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال الاسم" : null,
      ),
      FormFieldConfig(
        key: "unit",
        hint: "وحدة القياس",
        icon: const Icon(Icons.straighten, color: Colors.grey),
        options: ["حبة", "كرتون", "لفة", "متر"],
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء اختيار وحدة القياس" : null,
      ),
    ];

    _controllers = {for (var f in fields) f.key: TextEditingController()};
    _obscureMap = {for (var f in fields) f.key: f.isPassword};
  }

  Future<String?> _uploadImageToFirebase(XFile imageFile) async {
    try {
      final fileName =
          'materials/${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.name)}';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb) {
        Uint8List data = await imageFile.readAsBytes();
        final uploadTask = await storageRef.putData(data);
        return await uploadTask.ref.getDownloadURL();
      } else {
        File file = File(imageFile.path);
        final uploadTask = await storageRef.putFile(file);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint("Erreur upload Firebase: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // permet au bottom sheet de prendre plus de place
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: FractionallySizedBox(
          heightFactor: 0.20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text("اختر من المعرض"),
                onTap: () async {
                  final picked = await _picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null && mounted) {
                    setState(() => _selectedImage = picked);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text("التقط صورة بالكاميرا"),
                onTap: () async {
                  final picked = await _picker.pickImage(
                      source: ImageSource.camera, imageQuality: 80);
                  if (picked != null && mounted) {
                    setState(() => _selectedImage = picked);
                  }
                  Navigator.pop(context);
                  },
              ),
            ],
          ),
        ),
      ),
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
          constraints: const BoxConstraints(
            minHeight: 500,
          ),
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
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),

                // 🖼️ Image section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade100,
                      image: _selectedImage != null
                          ? DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_selectedImage!.path)
                            : FileImage(File(_selectedImage!.path))
                        as ImageProvider,
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Center(
                      child: Icon(Icons.camera_alt,
                          color: Colors.grey, size: 40),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Champs dynamiques
                ...fields.map((field) {
                  if (field.options != null && field.options!.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: NewRoundSelectField(
                        hintText: field.hint,
                        options: field.options!,
                        controller: _controllers[field.key],
                        validator: field.validator,
                        rightIcon: field.icon,
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
                              String imageUrl = "";
                              if (_selectedImage != null) {
                                final uploadedUrl = await _uploadImageToFirebase(_selectedImage!);
                                if (uploadedUrl != null) {
                                  imageUrl = uploadedUrl;
                                } else {
                                  if (mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      message: "فشل تحميل الصورة إلى Firebase 😢",
                                      type: SnackBarType.error,
                                    );
                                  }
                                  return;
                                }
                              }

                              final material = Materials(
                                name: _controllers["name"]!.text.trim(),
                                unit: _controllers["unit"]!.text.trim(),
                                image: imageUrl,
                                projectId: widget.projectId,
                              );

                              final addMaterialUseCase = sl<AddMaterialUseCase>();
                              final result = await addMaterialUseCase.call(params: material);

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
                                  // id retourné par Firebase
                                  final newMaterial = Materials(
                                    id: id,
                                    name: material.name,
                                    unit: material.unit,
                                    image: material.image,
                                    projectId: material.projectId,
                                  );

                                  CustomSnackBar.show(
                                    context,
                                    message: "تمت إضافة المادة بنجاح ✅",
                                    type: SnackBarType.success,
                                  );

                                  _sendNotification(
                                    title: "مادة جديد",
                                    message: "تم إضافة مادة جديدة: ${newMaterial.name}",
                                    userId: id,
                                    route: null,
                                  );

                                  // Transmettre les valeurs avec l'id à la liste
                                  widget.onAdd({
                                    "id": newMaterial.id ?? "",
                                    "name": newMaterial.name ?? "",
                                    "unit": newMaterial.unit ?? "",
                                    "image": newMaterial.image ?? "",
                                  });

                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              if (mounted) {
                                CustomSnackBar.show(
                                  context,
                                  message: "حدث خطأ غير متوقع: ${e.toString()}",
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
}
