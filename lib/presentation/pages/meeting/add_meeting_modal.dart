import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_meeting.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
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

class AddMeetingModal extends StatefulWidget {
  final Function(Map<String, String> values) onAdd;
  final String title;
  final String submitButtonText;

  const AddMeetingModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة محضر جديد",
    this.submitButtonText = "إضافة",
  });

  @override
  State<AddMeetingModal> createState() => _AddMeetingModalState();
}

class _AddMeetingModalState extends State<AddMeetingModal> {
  final _formKey = GlobalKey<FormState>();
  String? _signatureBase64;
  String? selectedCustomerPhone;

  // 🖼️ Image
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
 // ✒️ Signature
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImageToFirebase(XFile imageFile) async {
    try {
      final fileName =
          'meetings/${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.name)}';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb) {
        Uint8List data = await imageFile.readAsBytes();
        final task = await storageRef.putData(data);
        return await task.ref.getDownloadURL();
      } else {
        File file = File(imageFile.path);
        final task = await storageRef.putFile(file);
        return await task.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint("Erreur upload: $e");
      return null;
    }
  }

  // ============= AUTRES VARIABLES =============
  List<Engineer> engineers = [];
  List<Employees> employees = [];
  List<Customers> customers = [];

  String? selectedEngineerId;
  String? selectedEmployeeId;
  String? selectedCustomerId;
  bool _showSignature = false;
  String? signatureUrl;
  String? _meetingType;


  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;

  late final CreateNotificationUseCase _createNotificationUseCase;

  final TextEditingController engineerCtrl = TextEditingController();
  final TextEditingController employeeCtrl = TextEditingController();
  final TextEditingController customerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadEngineers();
    _loadEmployees();
    _loadCustomers();

    fields = [
      FormFieldConfig(
        key: "titleMeeting",
        hint: "عنوان الاجتماع",
        icon: const Icon(Icons.title, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال عنوان الاجتماع" : null,
      ),
      FormFieldConfig(
        key: "description",
        hint: "تفاصيل الاجتماع",
        icon: const Icon(Icons.description, color: Colors.grey),
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء إدخال التفاصيل" : null,
      ),
      FormFieldConfig(
        key: "type",
        hint: "نوع الاجتماع",
        icon: const Icon(Icons.category, color: Colors.grey),
        options: ["مع العميل", "مع الموظفين"],
        validator: (v) =>
        (v == null || v.isEmpty) ? "الرجاء اختيار نوع الاجتماع" : null,
      ),
    ];

    _controllers = {for (var f in fields) f.key: TextEditingController()};
    _obscureMap = {for (var f in fields) f.key: f.isPassword};
  }

  // 🔔 Notification
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

  // ========== LOAD DATA ==========
  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold(
          (e) => debugPrint("Error engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)),
    );
  }

  Future<void> _loadEmployees() async {
    final result = await sl<GetEmployeeUseCase>().call();
    result.fold(
          (e) => debugPrint("Error employees"),
          (list) => setState(() => employees = List<Employees>.from(list)),
    );
  }

  Future<void> _loadCustomers() async {
    final result = await sl<GetCustomerUseCase>().call();
    result.fold(
          (e) => debugPrint("Error customers"),
          (list) => setState(() => customers = List<Customers>.from(list)),
    );
  }


  Future<String?> _uploadSignatureToFirebase(Uint8List bytes) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('signatures/meeting_${DateTime.now().millisecondsSinceEpoch}.png');

      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );

      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Signature upload error: $e");
      return null;
    }
  }

  // ==== champs paragraphe existant ====
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
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          constraints: const BoxConstraints(minHeight: 700),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(   // ← ajouté ici
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

                  // === Image ajoutée ===
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

                  // === Dynamic Fields ===
                  ...fields.map((field) {
                    if (field.key == "description") {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildParagraphField(field),
                      );
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
                          onChanged: (value) {
                            setState(() {
                              _meetingType = value;
                              _showSignature = value == "مع العميل";
                            });
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
                  if (_controllers["type"]!.text == "مع العميل")
                    _buildSignatureSection(),

                  const SizedBox(height: 10),

                  // === Select engineer / customer / employee ===
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NewRoundSelectField(
                      hintText: "اختيار المهندس",
                      options: engineers.map((e) => e.firstName ?? "").toList(),
                      controller: engineerCtrl,
                      rightIcon: const Icon(Icons.engineering),
                      onChanged: (value) {
                        final engineer =
                        engineers.firstWhere((e) => e.firstName == value);
                        selectedEngineerId = engineer.id;
                      },
                    ),
                  ),
                  if (_meetingType == "مع العميل")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NewRoundSelectField(
                      hintText: "اختيار العميل",
                      options:
                      customers.map((c) => c.firstName ?? "").toList(),
                      controller: customerCtrl,
                      rightIcon: const Icon(Icons.person),
                      onChanged: (value) {
                        final customer =
                        customers.firstWhere((c) => c.firstName == value);
                        selectedCustomerId = customer.id;
                        selectedCustomerPhone = customer.phone;
                      },
                    ),
                  ),
                  if (_meetingType == "مع الموظفين")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NewRoundSelectField(
                      hintText: "اختيار الموظف",
                      options: employees.map((e) => e.firstName ?? "").toList(),
                      controller: employeeCtrl,
                      rightIcon: const Icon(Icons.account_circle),
                      onChanged: (value) {
                        final employee =
                        employees.firstWhere((e) => e.firstName == value);
                        selectedEmployeeId = employee.id;
                      },
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TColor.secondary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding:
                            const EdgeInsets.symmetric(vertical: 15),
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
                                borderRadius: BorderRadius.circular(30)),
                            padding:
                            const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                String imageUrl = "";
                                if (_selectedImage != null) {
                                  final uploadedUrl =
                                  await _uploadImageToFirebase(_selectedImage!);
                                  if (uploadedUrl != null) {
                                    imageUrl = uploadedUrl;
                                  }
                                }

                                if (_showSignature) {
                                  if (_signatureController.isEmpty) {
                                    CustomSnackBar.show(
                                      context,
                                      message: "التوقيع الإلكتروني مطلوب لاجتماع مع العميل",
                                      type: SnackBarType.warning,
                                    );
                                    return;
                                  }

                                  final bytes = await _signatureController.toPngBytes();
                                  if (bytes != null) {
                                    signatureUrl = await _uploadSignatureToFirebase(bytes);
                                  }
                                }
                                final meeting = Meeting(
                                  description:
                                  _controllers["description"]!.text.trim(),
                                  titleMeeting:
                                  _controllers["titleMeeting"]!.text.trim(),
                                  type:
                                  _controllers["type"]!.text.trim(),
                                  nameEngineer: engineerCtrl.text.trim(),
                                  uidEngineer: selectedEngineerId,
                                  nameEmployee: employeeCtrl.text.trim(),
                                  uidEmployee: selectedEmployeeId,
                                  nameCustomer: customerCtrl.text.trim(),
                                  uidCustomer: selectedCustomerId,
                                  imageUrl: imageUrl, // ajouté
                                  signatureUrl: signatureUrl,
                                  customerPhone: selectedCustomerPhone,
                                );

                                final addMeetingUseCase =
                                sl<AddMeetingUseCase>();

                                final result = await addMeetingUseCase.call(
                                    params: meeting);

                                result.fold(
                                      (failure) {
                                    CustomSnackBar.show(
                                      context,
                                      message:
                                      "حدث خطأ أثناء إضافة الاجتماع.",
                                      type: SnackBarType.error,
                                    );
                                  },
                                      (success) {
                                    CustomSnackBar.show(
                                      context,
                                      message:
                                      "تمت إضافة الاجتماع بنجاح.",
                                      type: SnackBarType.success,
                                    );

                                    _sendNotification(
                                      title: "اجتماع جديد",
                                      message:
                                      "تم إضافة اجتماع جديد: ${_controllers["titleMeeting"]!.text.trim()}",
                                      userId: success,
                                      route: "/home",
                                    );

                                    widget.onAdd({
                                      "description":
                                      _controllers["description"]!.text
                                          .trim(),
                                      "titleMeeting":
                                      _controllers["titleMeeting"]!.text
                                          .trim(),
                                      "type":
                                      _controllers["type"]!.text.trim(),
                                      "nameEngineer":
                                      engineerCtrl.text.trim(),
                                      "uidEngineer":
                                      selectedEngineerId ?? "",
                                      "nameEmployee":
                                      employeeCtrl.text.trim(),
                                      "uidEmployee":
                                      selectedEmployeeId ?? "",
                                      "nameCustomer":
                                      customerCtrl.text.trim(),
                                      "uidCustomer":
                                      selectedCustomerId ?? "",
                                      "imageUrl": imageUrl,
                                     "signatureUrl": signatureUrl ?? "",
                                      'customerPhone': selectedCustomerPhone ?? "",

                                    });

                                    Navigator.pop(context);
                                  },
                                );
                              } catch (e) {
                                CustomSnackBar.show(
                                  context,
                                  message: "حدث خطأ غير متوقع: $e",
                                  type: SnackBarType.error,
                                );
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
      ),
    );
  }
  Widget _buildSignatureSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "التوقيع الإلكتروني",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Stack(
            children: [
              // ✒️ Signature zone
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ),

              // 🗑️ Clear icon (top-left)
              Positioned(
                top: 8,
                left: 8,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    _signatureController.clear();
                    setState(() {
                      _signatureBase64 = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
