import 'dart:io';
import 'dart:typed_data';
import 'package:app_bhb/common_widget/app_keys.dart';
import 'package:app_bhb/data/auth/models/attachments_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/source/attachments_firebase_service.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/repository/attachments_repository.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attachemants.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/projects/add_project_attachement.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import '../../../service_locator.dart';
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
  final List<Map<String, dynamic>> _projectAttachments = [];
  late final NotificationService _notificationService;
  late final CreateNotificationUseCase _createNotificationUseCase;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _notificationService = NotificationService(_createNotificationUseCase);
    _loadProjectAttachments();
  }

  /// Charger les attachments depuis Firestore
  Future<void> _loadProjectAttachments() async {
    try {
      final result = await sl<AttachmentsFirebaseService>()
          .getAttachmentsByProjectId(widget.projectId);

      result.fold(
            (error) => CustomSnackBar.show(context, message: error, type: SnackBarType.error),
            (attachments) {
          setState(() {
            _projectAttachments.clear();
            _projectAttachments.addAll(attachments.map((att) => att.toMap()));
          });
        },
      );
    } catch (e) {
      CustomSnackBar.show(context, message: e.toString(), type: SnackBarType.error);
    }
  }

  /// Preview PDF / Image
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
                    final response = await http.get(Uri.parse(att["fileUrl"]!));
                    bytes = response.bodyBytes;
                  } else {
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

  /// Supprimer attachment
  void _deleteAttachment(Map<String, dynamic> att) async {
    if (att["id"] == null) return;

    final result = await sl<DeleteAttachmentUseCase>().call(params: att["id"]);

    result.fold(
          (failure) => CustomSnackBar.show(context, message: "خطأ في الحذف: $failure", type: SnackBarType.error),
          (_) {
        CustomSnackBar.show(context, message: "تم حذف المرفق بنجاح", type: SnackBarType.success);
        _loadProjectAttachments();
      },
    );
  }

  /// Envoyer notification
  Future<void> _sendNotification({required String title, required String message, String? userId, String? route}) async {
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

  /// Ajouter un fichier
  Future<void> _addAttachment() async {
    // Affiche le modal pour sélectionner le fichier
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProjectAttachment(projectId: widget.projectId),
    );

    if (result == null) return;

    final file = result["file"] as File?;
    final fileBytes = result["fileBytes"] as Uint8List?;
    final fileName = result["fileName"] as String?;
    final fileType = result["fileType"] as String?;
    final description = result["description"] as String?;

    if ((file == null && fileBytes == null) || fileName == null) {
      CustomSnackBar.show(
        context,
        message: "يرجى اختيار ملف وإدخال وصف",
        type: SnackBarType.error,
      );
      return;
    }

    // Affiche loader initial
    CustomSnackBar.show(
      context,
      message: "جاري رفع الملف...",
      type: SnackBarType.loading,
      duration: const Duration(days: 1),
    );

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileUrl = ''; // <-- corrigé pour Dart (assignation initiale)

      // Fonction interne pour gérer l'upload avec progression
      Future<void> uploadWithProgress() async {
        final ref = FirebaseStorage.instance
            .ref('attachments/$timestamp\_$fileName');

        UploadTask uploadTask;

        if (kIsWeb && fileBytes != null) {
          // ✅ Flutter Web (بدون dart:html)
          uploadTask = ref.putData(
            fileBytes,
            SettableMetadata(contentType: 'application/octet-stream'),
          );
        } else if (!kIsWeb && file != null) {
          // ✅ Mobile / Desktop
          uploadTask = ref.putFile(file);
        } else {
          throw Exception("File missing");
        }

        uploadTask.snapshotEvents.listen((event) {
          final progress =
              (event.bytesTransferred / event.totalBytes) * 100;


        });

        final snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
      }


      // Lance l'upload
      await uploadWithProgress();

      // Supprime le loader
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();

      // Crée l'objet Attachments
      final attachment = Attachments(
        projectId: widget.projectId,
        fileName: fileName,
        fileType: fileType,
        fileUrl: fileUrl,
        description: description ?? "",
      );

      // Ajoute dans Firestore
      final res = await sl<AttachmentsRepository>().addAttachment(attachment);

      res.fold(
            (l) {
          print("❌ Firestore Error: $l");
          CustomSnackBar.show(
            context,
            message: "حدث خطأ: $l",
            type: SnackBarType.error,
          );
        },
            (r) {
          print("✅ Firestore ajouté : ${r.fileName}");
          CustomSnackBar.show(
            context,
            message: "تم إضافة المرفق بنجاح ✅",
            type: SnackBarType.success,
          );

          // Notification
          _sendNotification(
            title: "مرفق جديد",
            message: "تم إضافة مرفق جديد: ${attachment.fileName}",
            userId: currentUserId,
            route: "/home",
          );

          // Recharge la liste
          _loadProjectAttachments();
        },
      );
    } catch (e, stack) {
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      debugPrint("===== ERREUR UPLOAD =====");
      debugPrint("Exception: $e");
      debugPrintStack(stackTrace: stack);
      CustomSnackBar.show(
        context,
        message: "حدث خطأ أثناء رفع الملف: $e",
        type: SnackBarType.error,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          /// Header + Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📘 مرفقات المشروع",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addAttachment,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text("إضافة مرفق"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// Liste des attachments
          _projectAttachments.isEmpty
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
            children: _projectAttachments
                .map((att) => _buildAttachmentCard(att))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Card pour chaque attachment
  Widget _buildAttachmentCard(Map<String, dynamic> att) {
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
                    if (att["createdAt"] != null)
                      Text(
                        DateTime.parse(att["createdAt"]).toLocal().toString().split('.')[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteAttachment(att),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                tooltip: "حذف المرفق",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

