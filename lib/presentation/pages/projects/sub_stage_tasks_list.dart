import 'dart:convert';
import 'dart:io';

import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' hide FormFieldConfig;
import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks.dart';
import 'package:app_bhb/presentation/pages/projects/predefined_phases.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as gfm;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';

import '../../../service_locator.dart';

class SubStageTasksList extends StatefulWidget {
  final String subStageId;
  final String projectId;

  const SubStageTasksList({
    super.key,
    required this.subStageId,
    required this.projectId,
  });

  @override
  State<SubStageTasksList> createState() => _SubStageTasksListState();
}

class _SubStageTasksListState extends State<SubStageTasksList> {
  List<Tasks> tasks = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }
  String getStageIdOfSubStage(String subStageId) {
    for (var phase in predefinedPhasesStructure) {
      final sub = (phase['subPhases'] as List<Map<String, dynamic>>)
          .firstWhereOrNull((s) => s['id'] == subStageId);
      if (sub != null) return phase['id'] as String;
    }
    return ''; // fallback si non trouvé
  }
  Future<void> _fetchTasks() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await sl<GetTasksBySubStageUseCase>().call(
      params: GetTasksBySubStageParams(
        projectId: widget.projectId,
        subStageId: widget.subStageId,
      ),
    );

    result.fold(
          (err) {
        setState(() {
          error = err;
          tasks = [];
          isLoading = false;
        });
      },
          (list) {
        setState(() {
          tasks = list;
          isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));
    if (tasks.isEmpty) return const Center(child: Text("لا توجد مهام بعد"));

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final stageId = getStageIdOfSubStage(widget.subStageId);
        return TaskModernCard(
          stageId: stageId,
          task: task,
          onTaskDeleted: () {
            setState(() {
              tasks.removeWhere((t) => t.id == task.id);
            });
          },
          onTaskUpdated: _fetchTasks, // tu peux recharger si nécessaire
        );
      },
    );
  }
}

class TaskModernCard extends StatelessWidget {
  final Tasks task;
  final VoidCallback onTaskDeleted;
  final VoidCallback onTaskUpdated;
  final String stageId;

  TaskModernCard({
    super.key,
    required this.task,
    required this.onTaskDeleted,
    required this.onTaskUpdated,
    required this.stageId,
  });

  final _deleteTaskUseCase = sl<DeleteTaskUseCase>();
  final _updateTaskUseCase = sl<UpdateTaskUseCase>();
  bool get isCeilingStage {
    return stageId == 'phase_08' ||
        stageId == 'phase_09' ||
        stageId == 'phase_10';
  }
  final Map<String, String> floorMap = {
    'الدور الأرضي': 'ground',
    'الدور الأول': 'floor_1',
    'الدور الثاني': 'floor_2',
    'الدور الثالث': 'floor_3',
    'الدور الرابع': 'floor_4',
    'الدور الخامس': 'floor_5',
    'السطح': 'roof',
  };


  String getFloorLabel(String? floorId) {
    switch (floorId) {
      case 'ground':
        return '🧱 الدور الأرضي';
      case 'floor_1':
        return '🧱 الدور الأول';
      case 'floor_2':
        return '🧱 الدور الثاني';
      case 'floor_3':
        return '🧱 الدور الثالث';
      case 'floor_4':
        return '🧱 الدور الرابع';
      case 'floor_5':
        return '🧱 الدور الخامس';

      case 'roof':
        return '🧱 السطح';
      default:
        return '';
    }
  }
  Future<String> uploadImageMobile(File file) async {
    final fileName = "tasks/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref(fileName);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
  Future<String> uploadImageWeb(Uint8List bytes) async {
    final fileName = "tasks/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref(fileName);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }


  @override
  Widget build(BuildContext context) {
    final rootContext = context;
    final floorLabel = getFloorLabel(task.floorId);
    List<Object> imagesBefore = List<Object>.from(task.imagesBefore ?? []);
    List<Object> imagesAfter = List<Object>.from(task.imagesAfter ?? []);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor
          if (floorLabel.isNotEmpty) ...[
            Text(
              floorLabel,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Notes
          Row(
            children: const [
              Icon(Icons.notes, color: Colors.blueGrey, size: 20),
              SizedBox(width: 6),
              Text(
                "الملاحظات",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.notes ?? "—",
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),

          // Images Before
          TaskImagesSection(
            title: "قبل العمل",
            icon: Icons.image_outlined,
            images: (task.imagesBefore ?? []).whereType<String>().toList(),
          ),
          if (imagesBefore.isNotEmpty) const SizedBox(height: 14),

          // Images After
          TaskImagesSection(
            title: "بعد العمل",
            icon: Icons.check_circle_outline,
            images: (task.imagesAfter ?? []).whereType<String>().toList(),
          ),
          if (imagesAfter.isNotEmpty) const SizedBox(height: 14),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Edit
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                tooltip: "تعديل المهمة",
                onPressed: () async {
                  final notesController = TextEditingController(text: task.notes);

                  // 🔹 Map عربي → إنجليزي للطوابق
                  final Map<String, String> floorMap = {
                    'الدور الأرضي': 'ground',
                    'الدور الأول': 'floor_1',
                    'الدور الثاني': 'floor_2',
                    'الدور الثالث': 'floor_3',
                    'الدور الرابع': 'floor_4',
                    'الدور الخامس': 'floor_5',
                    'السطح': 'roof',
                  };
                  final floorOptionsArabic = floorMap.keys.toList();

                  // 🔹 Valeur sélectionnée (إنجليزي) + تحويل للعرض بالعربي
                  String? selectedFloorId = task.floorId;
                  String? selectedFloorLabel = floorMap.entries
                      .firstWhere(
                        (e) => e.value == selectedFloorId,
                    orElse: () => MapEntry('', ''),
                  )
                      .key;

                  // 🔹 Images existantes
                  List<Object> imagesBeforeUrls = List<Object>.from(task.imagesBefore ?? []);
                  List<Object> imagesAfterUrls = List<Object>.from(task.imagesAfter ?? []);

                  // 🔹 Nouvelles images à ajouter
                  List<File> imagesBeforeMobile = [];
                  List<File> imagesAfterMobile = [];
                  List<Uint8List> imagesBeforeWeb = [];
                  List<Uint8List> imagesAfterWeb = [];

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => StatefulBuilder(
                      builder: (context, setModalState) {
                        final picker = ImagePicker();

                        Future<void> _showPickImageSheet({
                          required bool isBefore,
                          required BuildContext modalContext,
                        }) async {
                          final picker = ImagePicker();

                          await showModalBottomSheet(
                            context: modalContext,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (bottomSheetContext) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                  bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                                ),
                                child: FractionallySizedBox(
                                  heightFactor: 0.22,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      /// 📂 Galerie
                                      ListTile(
                                        leading: const Icon(Icons.photo_library, color: Colors.blue),
                                        title: const Text("اختر من المعرض (يمكنك اختيار عدة صور)"),
                                        onTap: () async {
                                          final pickedFiles =
                                          await picker.pickMultiImage(
                                            imageQuality: 55,
                                            maxWidth: 1280,
                                            maxHeight: 1280,
                                          );


                                          if (pickedFiles.isNotEmpty) {
                                            if (kIsWeb) {
                                              final bytesList = await Future.wait(
                                                pickedFiles.map((e) => e.readAsBytes()),
                                              );
                                              setModalState(() {
                                                if (isBefore) {
                                                  imagesBeforeWeb.addAll(bytesList);
                                                } else {
                                                  imagesAfterWeb.addAll(bytesList);
                                                }
                                              });
                                            } else {
                                              setModalState(() {
                                                if (isBefore) {
                                                  imagesBeforeMobile
                                                      .addAll(pickedFiles.map((e) => File(e.path)));
                                                } else {
                                                  imagesAfterMobile
                                                      .addAll(pickedFiles.map((e) => File(e.path)));
                                                }
                                              });
                                            }
                                          }
                                          Navigator.pop(bottomSheetContext);
                                        },
                                      ),

                                      /// 📷 Camera
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt, color: Colors.green),
                                        title: const Text("التقط صورة بالكاميرا"),
                                        onTap: () async {
                                          final picked = await picker.pickImage(
                                            source: ImageSource.camera,
                                            imageQuality: 55,
                                            maxWidth: 1280,
                                            maxHeight: 1280,
                                          );


                                          if (picked != null) {
                                            if (kIsWeb) {
                                              final bytes = await picked.readAsBytes();
                                              setModalState(() {
                                                if (isBefore) {
                                                  imagesBeforeWeb.add(bytes);
                                                } else {
                                                  imagesAfterWeb.add(bytes);
                                                }
                                              });
                                            } else {
                                              setModalState(() {
                                                if (isBefore) {
                                                  imagesBeforeMobile.add(File(picked.path));
                                                } else {
                                                  imagesAfterMobile.add(File(picked.path));
                                                }
                                              });
                                            }
                                          }
                                          Navigator.pop(bottomSheetContext);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        Widget _buildImageWidget(Object image, bool isBefore) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: image is String
                                    ? (image.startsWith("http")
                                    ? Image.network(
                                  image,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                                )
                                    : Image.memory(
                                  base64Decode(image),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ))
                                    : kIsWeb
                                    ? Image.memory(image as Uint8List, width: 80, height: 80, fit: BoxFit.cover)
                                    : Image.file(image as File, width: 80, height: 80, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: -5,
                                left: -5,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setModalState(() {
                                      if (image is String) {
                                        if (isBefore)
                                          imagesBeforeUrls.remove(image);
                                        else
                                          imagesAfterUrls.remove(image);
                                      } else if (image is File) {
                                        if (isBefore)
                                          imagesBeforeMobile.remove(image);
                                        else
                                          imagesAfterMobile.remove(image);
                                      } else if (image is Uint8List) {
                                        if (isBefore)
                                          imagesBeforeWeb.remove(image);
                                        else
                                          imagesAfterWeb.remove(image);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }

                        Wrap _buildImagesWrap(bool isBefore) {
                          List<Object> images = [];
                          if (isBefore) {
                            images.addAll(imagesBeforeUrls);
                            images.addAll(kIsWeb ? imagesBeforeWeb : imagesBeforeMobile);
                          } else {
                            images.addAll(imagesAfterUrls);
                            images.addAll(kIsWeb ? imagesAfterWeb : imagesAfterMobile);
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...images.map((img) => _buildImageWidget(img, isBefore)).toList(),
                              GestureDetector(
                                onTap: () => _showPickImageSheet(
                                  isBefore: isBefore,
                                  modalContext: context,
                                ),
                                child: Container(
                                  height: 90,
                                  width: 90,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          );
                        }

                        return GenericFormModal(
                          title: "تعديل المهمة",
                          submitButtonText: "حفظ",
                          controllers: {
                            "notes": notesController,
                            "floorId": TextEditingController(text: selectedFloorLabel),
                            "imagesBefore": TextEditingController(),
                            "imagesAfter": TextEditingController(),
                          },
                          fields: [
                            gfm.FormFieldConfig(
                              key: "notes",
                              hint: "الملاحظات",
                              maxLines: 3,
                              validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال الملاحظات" : null,
                            ),
                            if (isCeilingStage)
                              gfm.FormFieldConfig(
                                key: "floorId",
                                hint: "اختر الطابق",
                                options: floorOptionsArabic,
                                initialValue: selectedFloorLabel,
                                validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار الطابق" : null,
                                onChanged: (value) {
                                  selectedFloorId = floorMap[value ?? ''];
                                },
                              ),
                            // Champs fantômes
                            gfm.FormFieldConfig(
                              key: "imagesBefore",
                              hint: "Images avant",
                            ),
                            gfm.FormFieldConfig(
                              key: "imagesAfter",
                              hint: "Images après",
                            ),
                          ],
                          extraFieldBuilders: {
                            "imagesBefore": (_, __) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                const Text("📸 صور قبل العمل"),
                                const SizedBox(height: 8),
                                _buildImagesWrap(true),
                                const SizedBox(height: 12),
                              ],
                            ),
                            "imagesAfter": (_, __) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                const Text("📸 صور بعد العمل"),
                                const SizedBox(height: 8),
                                _buildImagesWrap(false),
                                const SizedBox(height: 12),
                              ],
                            ),
                          },
                            onSubmit: (values) async {
                              final messenger = ScaffoldMessenger.of(rootContext);

                              // ❗ IMPORTANT : fermer le modal AVANT
                              Navigator.of(context, rootNavigator: true).pop();

                              // ⏳ Snackbar loading
                              CustomSnackBar.show(
                                rootContext,
                                message: "⏳ جاري تحديث المهمة...",
                                type: SnackBarType.loading,
                                duration: const Duration(seconds: 30),
                              );

                              try {
                                List<String> finalImagesBefore = [];
                                List<String> finalImagesAfter = [];

                                finalImagesBefore.addAll(imagesBeforeUrls.whereType<String>());
                                finalImagesAfter.addAll(imagesAfterUrls.whereType<String>());

                                if (kIsWeb) {
                                  for (var bytes in imagesBeforeWeb) {
                                    finalImagesBefore.add(await uploadImageWeb(bytes));
                                  }
                                  for (var bytes in imagesAfterWeb) {
                                    finalImagesAfter.add(await uploadImageWeb(bytes));
                                  }
                                } else {
                                  for (var file in imagesBeforeMobile) {
                                    finalImagesBefore.add(await uploadImageMobile(file));
                                  }
                                  for (var file in imagesAfterMobile) {
                                    finalImagesAfter.add(await uploadImageMobile(file));
                                  }
                                }

                                final floorLabelAr = values["floorId"] as String?;
                                final floorId = floorMap[floorLabelAr ?? ''];

                                final updatedTask = Tasks(
                                  id: task.id,
                                  notes: values["notes"],
                                  floorId: floorId,
                                  imagesBefore: finalImagesBefore,
                                  imagesAfter: finalImagesAfter,
                                  subStageId: task.subStageId,
                                  projectId: task.projectId,
                                );

                                final result = await _updateTaskUseCase.call(params: updatedTask);

                                messenger.hideCurrentSnackBar();

                                if (!rootContext.mounted) return;

                                result.fold(
                                      (failure) => CustomSnackBar.show(
                                    rootContext,
                                    message: "❌ خطأ: $failure",
                                    type: SnackBarType.error,
                                  ),
                                      (_) {
                                    CustomSnackBar.show(
                                      rootContext,
                                      message: "✅ تم تحديث المهمة بنجاح",
                                      type: SnackBarType.success,
                                    );
                                    onTaskUpdated();
                                  },
                                );
                              } catch (e, s) {
                                messenger.hideCurrentSnackBar();
                                if (!rootContext.mounted) return;

                                CustomSnackBar.show(
                                  rootContext,
                                  message: "❌ حدث خطأ أثناء التحديث",
                                  type: SnackBarType.error,
                                );

                                debugPrint("UPDATE TASK ERROR: $e");
                                debugPrintStack(stackTrace: s);
                              }
                            }

                        );
                      },
                    ),
                  );
                },
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: "حذف المهمة",
                onPressed: () async {
                  final confirm = await CustomDialog.show(
                    context,
                    title: "تأكيد الحذف",
                    message: "هل أنت متأكد أنك تريد حذف هذه المهمة؟",
                    type: DialogType.confirm,
                    confirmText: "حذف",
                    cancelText: "إلغاء",
                  );

                  if (confirm == true) {
                    final result = await _deleteTaskUseCase.call(params: task.id);
                    result.fold(
                          (failure) => CustomSnackBar.show(
                        context,
                        message: "خطأ في الحذف: $failure",
                        type: SnackBarType.error,
                      ),
                          (_) {
                        CustomSnackBar.show(
                          context,
                          message: "تم حذف المهمة بنجاح",
                          type: SnackBarType.success,
                        );
                        onTaskDeleted();
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class TaskImagesSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> images;

  const TaskImagesSection({
    super.key,
    required this.title,
    required this.icon,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[index],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, w, p) =>
                  p == null ? w : const Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
class TaskImagesPicker extends StatefulWidget {
  final String title;
  final List<String> initialImages;
  final Function(List<String>) onChanged;

  const TaskImagesPicker({
    super.key,
    required this.title,
    required this.initialImages,
    required this.onChanged,
  });

  @override
  State<TaskImagesPicker> createState() => _TaskImagesPickerState();
}

class _TaskImagesPickerState extends State<TaskImagesPicker> {
  late List<String> images;

  @override
  void initState() {
    super.initState();
    images = List.from(widget.initialImages);
  }

  void _remove(int index) {
    setState(() {
      images.removeAt(index);
      widget.onChanged(images);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(images[i], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -5,
                    left: -5,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                      onPressed: () => _remove(i),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
