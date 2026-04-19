import 'dart:io';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';


class AddProjectAttachment extends StatefulWidget {
  final String projectId;

  const AddProjectAttachment({super.key, required this.projectId});

  @override
  State<AddProjectAttachment> createState() =>
      _AddProjectAttachmentState();
}

class _AddProjectAttachmentState extends State<AddProjectAttachment> {
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _fileName;
  String? _fileType;

  final TextEditingController _descriptionController =
  TextEditingController();
  final TextEditingController _fileController =
  TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _fileName = file.name;
        _fileType = file.extension;
        _selectedFileBytes = kIsWeb ? file.bytes : null;
        _selectedFile =
        !kIsWeb ? File(file.path!) : null;
        _fileController.text = file.name;
      });
    }
  }

  void _submit() {
    if (_fileName == null ||
        _descriptionController.text.isEmpty) {
      CustomSnackBar.show(context,
          message: "يرجى اختيار ملف وإدخال وصف",
          type: SnackBarType.error);
      return;
    }

    Navigator.of(context).pop({
      "file": _selectedFile,
      "fileBytes": _selectedFileBytes,
      "fileName": _fileName,
      "fileType": _fileType,
      "description":
      _descriptionController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return GenericFormModal(
      title: "📝 إضافة مرفق للمشروع",
      submitButtonText: "إضافة",
      controllers: {
        "description": _descriptionController,
        "file": _fileController,
      },
      fields: [
        FormFieldConfig(
            key: "description",
            hint: "وصف المرفق",
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "يرجى إدخال وصف";
              }
              return null;
            },
            icon: Icon(Icons.description)),
        FormFieldConfig(key: "file", hint: ""),
      ],
      extraFieldBuilders: {
        "file": (field, controller) {
          return GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 60,
              padding:
              const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border:
                Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _fileType == "pdf"
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      _fileName ?? "اختر ملف",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.upload_file),
                ],
              ),
            ),
          );
        },
      },
      onSubmit: (_) => _submit(),
    );
  }
}







