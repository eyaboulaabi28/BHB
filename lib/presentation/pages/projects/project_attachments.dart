import 'dart:io';
import 'dart:typed_data';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/data/auth/models/attachments_model.dart';
import 'package:app_bhb/data/auth/source/attachments_firebase_service.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attachemants.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import '../../../service_locator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ProjectAttachments extends StatefulWidget {
  final String projectId;

  const ProjectAttachments({super.key, required this.projectId});

  @override
  State<ProjectAttachments> createState() => _ProjectAttachmentsState();
}

class _ProjectAttachmentsState extends State<ProjectAttachments> {
  final List<Map<String, dynamic>> _projectAttachements = [];
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _loadProjectAttachement();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());

  }

  Future<void> _loadProjectAttachement() async {
    try {
      final result = await sl<AttachmentsFirebaseService>()
          .getAttachmentsByProjectId(widget.projectId);

      result.fold(
            (error) {
          CustomSnackBar.show(context, message: error, type: SnackBarType.error);
        },
            (attachments) {
          setState(() {
            _projectAttachements.clear();
            _projectAttachements.addAll(attachments.map((att) => att.toMap()));
          });
        },
      );
    } catch (e) {
      CustomSnackBar.show(context, message: e.toString(), type: SnackBarType.error);
    }
  }


  void _addProjectAttachement() async {
    final parentContext = context;

    Uint8List? fileBytes;
    File? selectedFile;
    String? fileName;
    String? fileType;

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return GenericFormModal(
          title: "إضافة مرفق",
          includeImagePicker: true,
          fields: [
            FormFieldConfig(
              key: "description",
              hint: "أدخل وصف المرفق",
            ),
          ],
          onSubmit: (values) async {
            // 🔹 récupérer le fichier
            if (kIsWeb) {
              fileBytes = values["imageBytes"];
              fileName = values["fileName"];
              fileType = values["fileType"];
            } else {
              if (values["imagePath"] != null) {
                selectedFile = File(values["imagePath"]);
                fileName = values["fileName"];
                fileType = values["fileType"];
              }
            }

            // ❌ Aucun fichier sélectionné
            if ((kIsWeb && fileBytes == null) ||
                (!kIsWeb && selectedFile == null)) {
              CustomSnackBar.show(
                parentContext,
                message: "الرجاء اختيار ملف",
                type: SnackBarType.error,
              );
              return;
            }

            // ✅ fermer le modal immédiatement
            Navigator.pop(modalContext);

            // ⏳ Snackbar loading
            CustomSnackBar.show(
              parentContext,
              message: "جاري رفع المرفق...",
              type: SnackBarType.loading,
              duration: const Duration(seconds: 30),
            );

            try {
              final uniqueName =
                  "${DateTime.now().millisecondsSinceEpoch}_$fileName";

              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child("attachments/${widget.projectId!}/$uniqueName");

              UploadTask uploadTask;

              if (kIsWeb) {
                uploadTask = storageRef.putData(fileBytes!);
              } else {
                uploadTask = storageRef.putFile(selectedFile!);
              }

              final snapshot = await uploadTask;
              final downloadUrl = await snapshot.ref.getDownloadURL();

              final attachment = Attachments(
                projectId: widget.projectId,
                fileName: fileName!,
                description: values["description"],
                fileType: fileType,
                fileUrl: downloadUrl,
              );

              final result = await sl<AttachmentsFirebaseService>()
                  .addAttachment(attachment);

              result.fold(
                    (failure) {
                  CustomSnackBar.show(
                    parentContext,
                    message: "خطأ أثناء إضافة المرفق",
                    type: SnackBarType.error,
                  );
                },
                    (_) {
                  CustomSnackBar.show(
                    parentContext,
                    message: "تم إضافة المرفق بنجاح",
                    type: SnackBarType.success,
                  );

                  _notificationService.send(
                    title: "إضافة مرفق",
                    message: "تم إضافة المرفق: ${attachment.fileName}",
                    route: "/home",
                  );

                  setState(() {
                    _projectAttachements.add(attachment.toMap());
                  });
                },
              );
            } catch (e) {
              CustomSnackBar.show(
                parentContext,
                message: "حدث خطأ غير متوقع أثناء الرفع",
                type: SnackBarType.error,
              );
            }
          },
        );
      },
    );
  }

  String getPlatformVersion() {
    if (kIsWeb) {
      return "Web";
    } else {
      return Platform.version;
    }
  }

  void _openPreview(Map<String, dynamic> att) {
    showDialog(
      context: context,
      builder: (_) {
        if (att["fileType"] == "pdf") {
          return Dialog(
            child: SizedBox(
              height: 600,
              child: PdfPreview(
                build: (format) async {
                  Uint8List bytes;

                  if (kIsWeb) {
                    // Web: utiliser http.get
                    final response = await http.get(Uri.parse(att["fileUrl"]!));
                    bytes = response.bodyBytes;
                  } else {
                    // Mobile: utiliser NetworkAssetBundle
                    final network = NetworkAssetBundle(Uri.parse(att["fileUrl"]!));
                    final data = await network.load(att["fileUrl"]!);
                    bytes = data.buffer.asUint8List();
                  }

                  return bytes;
                },
              ),
            ),
          );
        }

        return Dialog(
          child: Image.network(att["fileUrl"]!),
        );
      },
    );
  }

  void _deleteAttachment(Map<String, dynamic> att) async {
    if (att["id"] == null) return;

    final result = await sl<DeleteAttachmentUseCase>().call(params: att["id"]);

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "خطأ  في الحذف  : $failure",
          type: SnackBarType.error,
        );
      },
          (_) {
        CustomSnackBar.show(
          context,
          message: "تم حذف المرفق بنجاح",
          type: SnackBarType.success,
        );
        _loadProjectAttachement();
      },
    );
  }



  Widget buildAttachmentItem(Map<String, dynamic> att) {
    return InkWell(
      onTap: () => _openPreview(att),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              att["fileType"] == "pdf"
                  ? Icons.picture_as_pdf
                  : Icons.image,
              color: TColor.primary,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                att["fileName"] ?? "",
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📘 مرفقات المشروع",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addProjectAttachement,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text("إضافة مرفق"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _projectAttachements.isEmpty
              ? Center(
            child: Column(
              children: [
                Icon(Icons.upload_file, color: Colors.grey.shade400, size: 70),
                const SizedBox(height: 8),
                const Text(
                  "لم تتم إضافة أي مرفقات بعد",
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : Column(
            children: _projectAttachements
                .map((att) => buildAttachmentCard(att))
                .toList(),
          ),

        ],
      ),
    );
  }


  Widget buildAttachmentCard(Map<String, dynamic> att) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _openPreview(att),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: att["fileType"] == "pdf" ? Colors.red.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  att["fileType"] == "pdf" ? Icons.picture_as_pdf : Icons.image,
                  color: att["fileType"] == "pdf" ? Colors.red : Colors.blue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      att["fileName"] ?? "",
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (att["description"] != null)
                      Text(
                        att["description"],
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    Text(
                      att["createdAt"] != null
                          ? DateTime.parse(att["createdAt"]).toLocal().toString().split('.')[0]
                          : "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _deleteAttachment(att),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: "حذف المرفق",
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


}
