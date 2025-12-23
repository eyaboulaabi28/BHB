import 'dart:io';
import 'dart:typed_data';
import 'package:app_bhb/data/auth/models/sub_tests_model.dart';
import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks_tests.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';

import '../../../service_locator.dart';


class AddTaskTestDialog extends StatefulWidget {
  final String testId;
  final String projectId;
  final String testName;
  final VoidCallback? onTaskAdded;


  const AddTaskTestDialog({
    super.key,
    required this.testId,
    required this.testName,
    required this.projectId,
    this.onTaskAdded,
  });

  @override
  State<AddTaskTestDialog> createState() => _AddTaskTestDialogState();
}

class _AddTaskTestDialogState extends State<AddTaskTestDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final AddTasksTestUseCase _addTasksTestUseCase = sl<AddTasksTestUseCase>();

  final TextEditingController _notesController = TextEditingController();

  // Images Mobile
  List<File> _imagesMobile = [];


  // Images Web
  List<Uint8List> _imagesWeb = [];


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
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.20,
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
                        final bytesList = await Future.wait(pickedFiles.map((e) => e.readAsBytes()));
                        setState(() {
                          if (isBefore) {
                            _imagesWeb = bytesList;
                          }
                        });
                      } else {
                        setState(() {
                          if (isBefore) {
                            _imagesMobile = pickedFiles.map((e) => File(e.path)).toList();
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
                            _imagesWeb.add(bytes);
                          }
                        });
                      } else {
                        setState(() {
                          if (isBefore) {
                            _imagesMobile.add(File(picked.path));
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
      final bytes = isBefore ? _imagesWeb[index] : _imagesWeb[index];
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
                    _imagesWeb.removeAt(index);
                  }
                });
              },
            ),
          ),
        ],
      );
    } else {
      final file = isBefore ? _imagesMobile[index] : _imagesMobile[index];
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
                    _imagesMobile.removeAt(index);
                  }
                });
              },
            ),
          ),
        ],
      );
    }
  }

  Future<String> _uploadFile({required String path, Uint8List? bytes}) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('tasksTests/$fileName');

    // ⚡ Ajoutez ce print ici pour debug
    print('Uploading ${kIsWeb ? "Web bytes" : "File"}: ${kIsWeb ? bytes!.length : path}');

    UploadTask uploadTask;
    if (kIsWeb) {
      if (bytes == null) throw Exception("No bytes provided for Web upload");
      uploadTask = ref.putData(bytes);
    } else {
      uploadTask = ref.putFile(File(path));
    }

    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }


  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
    });
    final parentContext = Navigator.of(context).context;
    final notes = _notesController.text.trim();
    Navigator.of(context).pop();
    // 🔒 لا نغلق الـ BottomSheet الآن
    CustomSnackBar.show(
      context,
      message: "جاري رفع الصور... الرجاء الانتظار",
      type: SnackBarType.loading,
      duration: const Duration(days: 1),
    );
    try {
      // 1️⃣ Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < (kIsWeb ? _imagesWeb.length : _imagesMobile.length); i++) {
        if (kIsWeb) {
          imageUrls.add(
            await _uploadFile(path: '', bytes: _imagesWeb[i]),
          );
        } else {
          imageUrls.add(
            await _uploadFile(path: _imagesMobile[i].path),
          );
        }
      }
      // 2️⃣ Construire l'entité TasksTests
      final taskTest = TasksTests(
        projectId: widget.projectId,
        subTestId: widget.testId,
        notes: notes,
        images: imageUrls,
      );
      // 3️⃣ Appeler le UseCase
      final result = await _addTasksTestUseCase(params: taskTest);
      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();

      CustomSnackBar.show(
        parentContext,
        message: "تمت إضافة المهمة بنجاح ✅",
        type: SnackBarType.success,
      );
      widget.onTaskAdded?.call();

      if (!mounted) return;

    } catch (e) {
      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();

      CustomSnackBar.show(
        parentContext,
        message: "حدث خطأ أثناء رفع الصور",
        type: SnackBarType.error,
      );
    } finally {
      _isSubmitting = false;
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
            minHeight: 500,
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
                    "📝 إضافة الاختبار إلى ${widget.testName}",
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
                  const SizedBox(height: 25),
                  Text("📸 صور", style: TextStyle(color: TColor.secondary, fontSize: 16)),
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
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _submit,
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
        ? (isBefore ? _imagesWeb.length : _imagesWeb.length)
        : (isBefore ? _imagesMobile.length : _imagesMobile.length);

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
