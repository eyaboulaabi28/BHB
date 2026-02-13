
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
  List<List<TaskItem>> _taskGroups = [];

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
  Future<void> _pickImage({int? groupIndex}) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text(
              "اختيار مصدر الصورة",
              style: TextStyle(
                fontFamily: "Tajawal",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// 📷 Camera
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text("التقط صورة بالكاميرا"),
              onTap: () async {
                Navigator.pop(context);

                final pickedFile =
                await _picker.pickImage(source: ImageSource.camera);

                if (pickedFile != null && mounted) {
                  if (groupIndex != null) {
                    _uploadAndAddImage(pickedFile, groupIndex);
                  } else {
                    setState(() {
                      _taskGroups.add([]);
                    });
                    _uploadAndAddImage(
                        pickedFile, _taskGroups.length - 1);
                  }
                }
              },
            ),

            /// 🖼️ Galerie (🔥 ajouté)
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("اختيار من المعرض"),
              onTap: () async {
                Navigator.pop(context);

                final List<XFile> images =
                await _picker.pickMultiImage();

                if (images.isNotEmpty && mounted) {
                  if (groupIndex != null) {
                    for (var img in images) {
                      _uploadAndAddImage(img, groupIndex);
                    }
                  } else {
                    setState(() {
                      _taskGroups.add([]);
                    });

                    int newIndex = _taskGroups.length - 1;

                    for (var img in images) {
                      _uploadAndAddImage(img, newIndex);
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndAddImage(XFile pickedFile, int groupIndex) async {
    final tempItem = TaskItem(
      imageUrl: pickedFile.path,
      remark: "",
      isUploading: true,
    );

    setState(() {
      _taskGroups[groupIndex].add(tempItem);
    });

    try {
      final fileName =
          "site_tasks/${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}";
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

      setState(() {
        tempItem.imageUrl = uploadedUrl;
        tempItem.isUploading = false;
      });
    } catch (e) {
      setState(() {
        _taskGroups[groupIndex].remove(tempItem);
      });
    }
  }



  // ===== Build the Images + Remarks widget for GenericFormModal =====
  Widget _imagesWithRemarksWidget() {
    const double cardSize = 110;

    // 🔹 Aucun groupe → afficher icône +
    if (_taskGroups.isEmpty) {
      return Center(
        child: GestureDetector(
          onTap: () => _pickImage(),
          child: Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.add_a_photo, size: 40),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        ..._taskGroups.asMap().entries.map((entry) {
          int groupIndex = entry.key;
          List<TaskItem> group = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Images horizontales
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [

                    ...group.map((item) {
                      return Stack(
                        children: [
                          Container(
                            width: cardSize,
                            height: cardSize,
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: item.isUploading
                                  ? null
                                  : DecorationImage(
                                image: item.imageUrl.startsWith("http")
                                    ? NetworkImage(item.imageUrl)
                                    : FileImage(File(item.imageUrl))
                                as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              color: item.isUploading
                                  ? Colors.grey.shade300
                                  : null,
                            ),
                            child: item.isUploading
                                ? const Center(
                                child: CircularProgressIndicator())
                                : null,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                group.remove(item);
                              }),
                              child: const Icon(Icons.cancel,
                                  color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }).toList(),

                    /// ➕ Ajouter image dans groupe
                    GestureDetector(
                      onTap: () =>
                          _pickImage(groupIndex: groupIndex),
                      child: Container(
                        width: cardSize,
                        height: cardSize,
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.add, size: 35),
                      ),
                    ),
                  ],
                ),
              ),

              /// 📝 Remarque du groupe
              NewRoundTextField(
                hintText: "ملاحظة على هذه المجموعة من الصور",
                maxLines: 3,
                onChanged: (v) {
                  if (group.isNotEmpty) {
                    group.first.remark = v ?? "";
                  }
                },
              ),

              /// 🗑 Supprimer groupe
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.red),
                  onPressed: () =>
                      setState(() => _taskGroups.removeAt(groupIndex)),
                ),
              ),

              const SizedBox(height: 15),
            ],
          );
        }).toList(),

        /// 🔹 Nouveau groupe
        GestureDetector(
          onTap: () => _pickImage(),
          child: Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.add_a_photo, size: 40),
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return GenericFormModal(
      title: "تفاصيل زيارة الموقع",
      submitButtonText: "تأكيد",
      onSubmit: (values) async {

        // 🔥 IMPORTANT : convertir les groupes en task.items
        task.items.clear();

        for (var group in _taskGroups) {
          task.items.addAll(group);
        }

        final service = sl<NewSiteFirebaseService>();

        final result = await service.updateTasksForSite(
          widget.siteId,
          task,
          generalRemarkCtrl.text.trim(),
        );

        result.fold(
              (failure) => CustomSnackBar.show(
              context,
              message: failure.toString(),
              type: SnackBarType.error
          ),
              (success) {
            CustomSnackBar.show(
                context,
                message: "تمت إضافة المهام بنجاح.",
                type: SnackBarType.success
            );

            final customerName =
                widget.site.customerName ?? "غير معروف";

            _sendNotification(
              title: "إضافة المهام للموقع الجديد",
              message:
              "تم إضافة المهام للموقع الجديد للعميل : $customerName",
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




