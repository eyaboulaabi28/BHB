
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/TaskItem.dart';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:app_bhb/data/auth/source/newSite_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../../service_locator.dart';

class AddSiteTasksModal extends StatefulWidget {
  final String siteId;
  final NewSite site;
  final void Function(List<SiteTask>, String generalRemark) onSubmit;

  const AddSiteTasksModal({super.key, required this.onSubmit,required this.siteId,required this.site,});

  @override
  State<AddSiteTasksModal> createState() => _AddSiteTasksModalState();
}

class _AddSiteTasksModalState extends State<AddSiteTasksModal> {
  final SiteTask task = SiteTask(items: []);
  final TextEditingController generalRemarkCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late final CreateNotificationUseCase _createNotificationUseCase;
  late String? currentUserId;

  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
  // ===== Pick Image with Camera or Gallery =====
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: FractionallySizedBox(
          heightFactor: 0.25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text("التقط صورة بالكاميرا"),
                onTap: () async {
                  final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null && mounted) _uploadAndAddImage(pickedFile);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text("اختيار صورة من المعرض"),
                onTap: () async {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null && mounted) _uploadAndAddImage(pickedFile);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadAndAddImage(XFile pickedFile) async {
    // Créer un item temporaire avec l'image locale
    final tempItem = TaskItem(
      imageUrl: pickedFile.path, // utiliser le chemin local pour l'affichage immédiat
      remark: "",
      isUploading: true, // marqueur pour savoir que c'est en cours d'upload
    );

    setState(() {
      task.items.add(tempItem);
    });

    try {
      final fileName = "site_tasks/${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}";
      final storageRef = FirebaseStorage.instance.ref(fileName);

      String uploadedUrl;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final uploadTask = await storageRef.putData(bytes);
        uploadedUrl = await uploadTask.ref.getDownloadURL();
      } else {
        final file = File(pickedFile.path);
        final uploadTask = await storageRef.putFile(file);
        uploadedUrl = await uploadTask.ref.getDownloadURL();
      }

      // Remplacer l'image locale par l'URL Firebase
      setState(() {
        tempItem.imageUrl = uploadedUrl;
        tempItem.isUploading = false;
      });
    } catch (e) {
      setState(() {
        task.items.remove(tempItem);
      });
      CustomSnackBar.show(context, message: "خطأ في تحميل الصورة", type: SnackBarType.error);
    }
  }


  // ===== Build the Images + Remarks widget for GenericFormModal =====
  Widget _imagesWithRemarksWidget() {
    const double cardSize = 100;
    List<Widget> widgets = [];

    for (int i = 0; i < task.items.length; i++) {
      final item = task.items[i];

      widgets.add(Stack(
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: item.isUploading
                  ? null
                  : DecorationImage(
                image: item.imageUrl.startsWith("http")
                    ? NetworkImage(item.imageUrl)
                    : FileImage(File(item.imageUrl)) as ImageProvider,
                fit: BoxFit.cover,
              ),
              color: item.isUploading ? Colors.grey.shade300 : null,
            ),
            child: item.isUploading
                ? const Center(child: CircularProgressIndicator())
                : null,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => task.items.removeAt(i)),
              child: const Icon(Icons.cancel, color: Colors.red, size: 22),
            ),
          ),
        ],
      ));

      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: NewRoundTextField(
          hintText: "ملاحظة على الصورة",
          onChanged: (v) => item.remark = v ?? "",
        ),
      ));
    }

    // Bouton Ajouter Image
    widgets.add(GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: cardSize,
        height: cardSize,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 35),
      ),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }


  @override
  Widget build(BuildContext context) {
    return GenericFormModal(
      title: "تفاصيل زيارة الموقع",
      submitButtonText: "تأكيد",
      onSubmit: (values) async {
        final service = sl<NewSiteFirebaseService>();
        final result = await service.updateTasksForSite(widget.siteId, task, generalRemarkCtrl.text.trim());


        result.fold(
              (failure) => CustomSnackBar.show(context, message: failure.toString(), type: SnackBarType.error),
              (success) {
            CustomSnackBar.show(context, message: "تمت إضافة المهام بنجاح.", type: SnackBarType.success);
            final customerName = widget.site.customerName ?? "غير معروف";

            _sendNotification(
              title: "إضافة المهام للموقع الجديد",
              message: "تم إضافة المهام للموقع الجديد للعميل : $customerName",
              route: "/home",
              userId: currentUserId,
            );
            Navigator.pop(context);
          },
        );

      },
      topWidget: _imagesWithRemarksWidget(),
      fields: [
        FormFieldConfig(
          key: "generalRemark",
          hint: "ملاحظة عامة على الزيارة",
          maxLines: 4,
        ),
      ],
      controllers: {
        "generalRemark": generalRemarkCtrl,
      },
    );
  }
}




