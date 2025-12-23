import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:path/path.dart' as path;

class GenericFormModal extends StatefulWidget {
  final List<FormFieldConfig> fields;
  final Function(Map<String, dynamic> values) onSubmit;
  final String title;
  final String submitButtonText;
  final Map<String, String>? initialValues;
  final bool includeImagePicker;
  final bool includeFilePicker;
  final bool readOnly;
  final Widget? topWidget;

  /// **Nouveaux paramètres**
  final Map<String, TextEditingController>? controllers;
  final Map<String, Widget Function(FormFieldConfig field, TextEditingController controller)>? extraFieldBuilders;

  const GenericFormModal({
    super.key,
    required this.fields,
    required this.onSubmit,
    this.title = "إضافة عنصر جديد",
    this.submitButtonText = "إضافة",
    this.initialValues,
    this.includeImagePicker = false,
    this.includeFilePicker = false,
    this.readOnly = false,
    this.controllers,
    this.extraFieldBuilders,
    this.topWidget,

  });

  @override
  State<GenericFormModal> createState() => _GenericFormModalState();
}

class _GenericFormModalState extends State<GenericFormModal> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  late Map<String, bool> _obscureMap;
  double? selectedLat; // <-- Ajouté
  double? selectedLng; // <-- Ajouté
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _fileName;
  String? _fileType;
  late String? _initialImageUrl;

  @override
  void initState() {
    super.initState();

    // Récupérer l'URL initiale
    _initialImageUrl = widget.initialValues?["image"];

    // Normaliser le type de fichier depuis l'URL initiale
    if (_initialImageUrl != null && _initialImageUrl!.isNotEmpty) {
      final uri = Uri.parse(_initialImageUrl!);
      final path = uri.path; // ignore query params éventuels
      _fileType = path.split('.').last.toLowerCase();
    }

    // ✅ Si des controllers sont fournis depuis l'extérieur, on les utilise
    if (widget.controllers != null) {
      _controllers = widget.controllers!;
    } else {
      _controllers = {
        for (var field in widget.fields)
          field.key: TextEditingController(
            text: widget.initialValues?[field.key] ?? '',
          ),
      };
    }

    _obscureMap = {for (var field in widget.fields) field.key: field.isPassword};
  }


  bool _isImage(String? fileType) {
    if (fileType == null) return false;
    final lower = fileType.toLowerCase();
    return ["png", "jpg", "jpeg", "gif", "bmp", "webp"].contains(lower);
  }


  Future<void> _pickFile() async {
    // Ouvre le file picker pour tous types de fichiers
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: kIsWeb, // si Web, récupère directement bytes
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (kIsWeb) {
      setState(() {
        _selectedImageBytes = file.bytes;
        _fileName = file.name;
        _fileType = file.extension ?? "unknown";
        _selectedImage = null; // pour éviter conflit
      });
    } else {
      setState(() {
        _selectedImage = File(file.path!);
        _fileName = file.name;
        _fileType = file.extension ?? "unknown";
        _selectedImageBytes = null;
      });
    }
  }
// Upload pour le Web (Uint8List)
  Future<String?> uploadToFirebaseWeb(Uint8List imageBytes, String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('materials/$fileName');
      final uploadTask = await storageRef.putData(imageBytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erreur upload Web: $e");
      return null;
    }
  }

// Upload pour Mobile (File)
  Future<String?> uploadToFirebaseMobile(File imageFile) async {
    try {
      final fileName = 'materials/${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erreur upload Mobile: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                  if (widget.topWidget != null) widget.topWidget!,

                  const SizedBox(height: 20),
                  if (widget.includeImagePicker) ...[
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey.shade100,

                          // ✅ Image uniquement si c’est une image
                          image: _isImage(_fileType)
                              ? (_selectedImage != null
                              ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                              : (_selectedImageBytes != null &&
                              _selectedImageBytes!.isNotEmpty
                              ? DecorationImage(
                            image: MemoryImage(_selectedImageBytes!),
                            fit: BoxFit.cover,
                          )
                              : (_initialImageUrl != null &&
                              _initialImageUrl!.trim().isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(_initialImageUrl!),
                            fit: BoxFit.cover,
                          )
                              : null)))
                              : null,
                        ),

                        // 🔴 🔴 🔴 ICI EXACTEMENT
                        child: _isImage(_fileType)
                            ? null
                            : Center(
                          child: Icon(
                            _fileType == "pdf"
                                ? Icons.picture_as_pdf
                                : Icons.insert_drive_file,
                            color: Colors.grey.shade700,
                            size: 50,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],

                  ...widget.fields.map((field) {
                    // Si un extraFieldBuilder existe pour ce champ, on l'utilise
                    if (widget.extraFieldBuilders != null && widget.extraFieldBuilders![field.key] != null) {
                      return widget.extraFieldBuilders![field.key]!(field, _controllers[field.key]!);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: field.options != null
                          ? NewRoundSelectField(
                        hintText: field.hint,
                        options: field.options!,
                        controller: _controllers[field.key],
                        validator: field.validator,
                        rightIcon: field.icon,
                        readOnly: widget.readOnly,
                      )
                          : NewRoundTextField(
                        hintText: field.hint,
                        controller: _controllers[field.key],
                        readOnly: widget.readOnly,
                        keyboardType: field.keyboardType,
                        obscureText: _obscureMap[field.key] ?? false,
                        right: field.isPassword
                            ? IconButton(
                          icon: Icon(
                            _obscureMap[field.key]!
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureMap[field.key] = !_obscureMap[field.key]!;
                            });
                          },
                        )
                            : field.icon,
                        validator: field.validator,
                      ),
                    );
                  }).toList(),
                 const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: TColor.secondary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
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
                                      borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    Map<String, dynamic> values = {
                                      for (var e in _controllers.entries) e.key: e.value.text,
                                    };

                                    // ✅ أضف هذا الجزء
                                    values["fileName"] = _fileName;
                                    values["fileType"] = _fileType;

                                    if (kIsWeb) {
                                      values["imageBytes"] = _selectedImageBytes;
                                    } else {
                                      values["imagePath"] = _selectedImage?.path;
                                    }

                                    widget.onSubmit(values);
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
                      ),
                    ),
                  )

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FormFieldConfig {
  final String key;
  final String hint;
  final Widget? icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<String>? options;
  final int maxLines;
  final bool isImagePicker;
  final String? label;

  FormFieldConfig({
    required this.key,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.options,
    this.maxLines = 1,
    this.isImagePicker = false,
    this.label,
  });

  factory FormFieldConfig.imagePicker({required String key, String? label}) {
    return FormFieldConfig(
      key: key,
      hint: "",
      label: label,
      isImagePicker: true,
    );
  }
}
