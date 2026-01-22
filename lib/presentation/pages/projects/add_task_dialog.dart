import 'dart:io';
import 'dart:typed_data';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/app_keys.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/sub_stages_model.dart';

import '../../../service_locator.dart';


class AddTaskDialog extends StatefulWidget {
  final SubStage subStage;
  final VoidCallback? onTaskAdded;
  final String? projectId;
  final String projectName;
  const AddTaskDialog({
    super.key,
    required this.subStage,
    required this.projectId,
    this.onTaskAdded,
    required this.projectName,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String? selectedFloorId;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  late final CreateNotificationUseCase _createNotificationUseCase;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _floorController.dispose();
    _notesController.dispose();
    super.dispose();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();

  }


  bool get isCeilingStage {
    return widget.subStage.stageId == 'phase_08'
        || widget.subStage.stageId == 'phase_09'
        || widget.subStage.stageId == 'phase_10';
  }

  // Images Mobile
  List<File> _imagesBefore = [];
  List<File> _imagesAfter = [];

  // Images Web
  List<Uint8List> _imagesBeforeWeb = [];
  List<Uint8List> _imagesAfterWeb = [];
  Future<Uint8List> compressMobile(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.path,
      quality: 50,
      keepExif: false,
    );

    if (result == null) {
      throw Exception("Compression failed (mobile)");
    }
    return result;
  }

  Future<Uint8List> compressWeb(Uint8List data) async {
    final result = await FlutterImageCompress.compressWithList(
      data,
      quality: 50,
      keepExif: false,
    );
    return result;
  }


  Future<void> _pickImage(bool isBefore) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20, // pour clavier
          ),
          child: FractionallySizedBox(
            heightFactor: 0.20, // ajuste selon la hauteur désirée
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text("اختر من المعرض (يمكنك اختيار عدة صور)"),
                  onTap: () async {
                    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
                    if (pickedFiles.isNotEmpty) {
                      if (!mounted) return;
                      if (kIsWeb) {
                        final bytesList = await Future.wait(
                          pickedFiles.map((e) => e.readAsBytes()),
                        );

                        setState(() {
                          if (isBefore) {
                            _imagesBeforeWeb.addAll(bytesList);
                          } else {
                            _imagesAfterWeb.addAll(bytesList);
                          }
                        });
                      }
                      else {
                        setState(() {
                          if (isBefore) {
                            _imagesBefore.addAll(
                              pickedFiles.map((e) => File(e.path)),
                            );
                          } else {
                            _imagesAfter.addAll(
                              pickedFiles.map((e) => File(e.path)),
                            );
                          }
                        });
                      }

                    }
                    Navigator.of(bottomSheetContext).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text("التقط صورة بالكاميرا"),
                  onTap: () async {
                    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (picked != null) {
                      if (!mounted) return;
                      if (kIsWeb) {
                        final bytes = await picked.readAsBytes();
                        setState(() {
                          if (isBefore) {
                            _imagesBeforeWeb.add(bytes);
                          } else {
                            _imagesAfterWeb.add(bytes);
                          }
                        });
                      } else {
                        setState(() {
                          if (isBefore) {
                            _imagesBefore.add(File(picked.path));
                          } else {
                            _imagesAfter.add(File(picked.path));
                          }
                        });
                      }
                    }
                    Navigator.of(bottomSheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(bool isBefore, int index) {
    if (kIsWeb) {
      final bytes = isBefore ? _imagesBeforeWeb[index] : _imagesAfterWeb[index];
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: -5,
            left: -5,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  if (isBefore) {
                    _imagesBeforeWeb.removeAt(index);
                  } else {
                    _imagesAfterWeb.removeAt(index);
                  }
                });
              },
            ),
          ),
        ],
      );
    } else {
      final file = isBefore ? _imagesBefore[index] : _imagesAfter[index];
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: -5,
            left: -5,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  if (isBefore) {
                    _imagesBefore.removeAt(index);
                  } else {
                    _imagesAfter.removeAt(index);
                  }
                });
              },
            ),
          ),
        ],
      );
    }
  }

  Future<String> _uploadFile({String? path, Uint8List? bytes}) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('tasks/$fileName.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      contentDisposition: 'inline',
    );
    UploadTask uploadTask;
    if (bytes != null) {
      // Web + mobile compressé
      uploadTask = ref.putData(bytes, metadata);
    } else if (path != null && path.isNotEmpty) {
      uploadTask = ref.putFile(File(path), metadata);
    } else {
      throw Exception("No data provided for upload");
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  bool _isSubmitting = false;


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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    _isSubmitting = true;
    final notes = _notesController.text.trim();

    // ⬅️ احفظ Context قبل pop
    final rootContext = context;

    CustomSnackBar.show(
      rootContext,
      message: "جاري رفع الصور... الرجاء الانتظار",
      type: SnackBarType.loading,
      duration: const Duration(days: 1),
    );

    // ⬅️ اغلق الـ BottomSheet
    Navigator.pop(rootContext);

    try {
      List<String> urlsBefore = [];
      for (int i = 0;
      i < (kIsWeb ? _imagesBeforeWeb.length : _imagesBefore.length);
      i++) {
        final compressed = kIsWeb
            ? await compressWeb(_imagesBeforeWeb[i])
            : await compressMobile(_imagesBefore[i]);

        urlsBefore.add(await _uploadFile(bytes: compressed));
      }

      List<String> urlsAfter = [];
      for (int i = 0;
      i < (kIsWeb ? _imagesAfterWeb.length : _imagesAfter.length);
      i++) {
        final compressed = kIsWeb
            ? await compressWeb(_imagesAfterWeb[i])
            : await compressMobile(_imagesAfter[i]);

        urlsAfter.add(await _uploadFile(bytes: compressed));
      }

      await FirebaseFirestore.instance.collection('tasks').add({
        'projectId': widget.projectId,
        'subStageId': widget.subStage.id,
        'notes': notes,
        'imagesBefore': urlsBefore,
        'imagesAfter': urlsAfter,
        'createdAt': FieldValue.serverTimestamp(),
        'floorId': selectedFloorId,
      });

      CustomSnackBar.show(
        rootContext,
        message: "تمت إضافة المهمة بنجاح",
        type: SnackBarType.success,
      );
      final notifMessage = "تمت إضافة مهمة جديدة\n"
          "المشروع: ${widget.projectName}\n"
          "المرحلة: ${widget.subStage.stageId}\n"
          "المهمة الفرعية: ${widget.subStage.subStageName}";
      await _sendNotification(
        title: "مهمة جديدة",
        message: notifMessage,
        userId: currentUserId,
        route: "/home",
      );
      widget.onTaskAdded?.call();

    } catch (e) {
      CustomSnackBar.show(
        rootContext,
        message: "حدث خطأ أثناء رفع الصور",
        type: SnackBarType.error,
      );
    } finally {
      _isSubmitting = false;
    }
  }






  String? _mapFloorLabelToId(String? label) {
    switch (label) {
      case 'الدور الأرضي':
        return 'ground';
      case 'الدور الأول':
        return 'floor_1';
      case 'الدور الثاني':
        return 'floor_2';
      case 'الدور الثالث':
        return 'floor_3';
      case 'الدور الرابع':
        return 'floor_4';
      case 'الدور الخامس':
        return 'floor_5';
      case 'السطح':
        return 'roof';
      default:
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
          constraints: const BoxConstraints(
            minHeight: 550,
          ),
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
                    "📝 إضافة مهمة إلى ${widget.subStage.subStageName}",
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  NewRoundTextField(
                    hintText: "أدخل الملاحظات",
                    controller: _notesController,
                    right: const Icon(Icons.note_alt_outlined, color: Colors.grey),
                    maxLines: 3,
                  ),
                  if (isCeilingStage) ...[
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "🧱 اختر الطابق",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TColor.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    NewRoundSelectField(
                      hintText: "اختر الطابق",
                      controller: _floorController,
                      options: const [
                        'الدور الأرضي',
                        'الدور الأول',
                        'الدور الثاني',
                        'الدور الثالث',
                        'الدور الرابع',
                        'الدور الخامس',
                        'السطح',
                      ],
                      validator: (value) {
                        if (isCeilingStage && (value == null || value.isEmpty)) {
                          return 'الرجاء اختيار الطابق';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // 🔥 UI فقط → ربط النص بالقيمة المنطقية
                        setState(() {
                          selectedFloorId = _mapFloorLabelToId(value);
                        });
                      },
                    ),
                    const SizedBox(height: 25),
                  ],
                  const SizedBox(height: 25),
                  Text("📸 صور قبل العمل", style: TextStyle(color: TColor.secondary, fontSize: 16)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.shade100,
                      ),
                      child: _buildImagesWrap(true),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text("📸 صور بعد العمل", style: TextStyle(color: TColor.secondary, fontSize: 16)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.shade100,
                      ),
                      child: _buildImagesWrap(false),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TColor.secondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("إلغاء",
                              style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: TColor.secondary)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child:
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _isSubmitting ? null : () => _submit(),
                          child: const Text("إضافة",
                              style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Wrap _buildImagesWrap(bool isBefore) {
    final length = kIsWeb
        ? (isBefore ? _imagesBeforeWeb.length : _imagesAfterWeb.length)
        : (isBefore ? _imagesBefore.length : _imagesAfter.length);

    if (length == 0) {
      return const Wrap(
        children: [Center(child: Icon(Icons.add_photo_alternate, color: Colors.grey, size: 40))],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(length, (index) => _buildImageWidget(isBefore, index)),
    );
  }
}
