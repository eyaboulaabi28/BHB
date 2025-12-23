import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/materials_usecases.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/materials/add_material_modal.dart';
import 'package:app_bhb/presentation/pages/projects/global_materials_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import '../../../service_locator.dart';

class ProjectRequestMaterials extends StatefulWidget {
  final String projectId;

  const ProjectRequestMaterials({super.key, required this.projectId});

  @override
  State<ProjectRequestMaterials> createState() => _ProjectRequestMaterialsState();
}


class _ProjectRequestMaterialsState extends State<ProjectRequestMaterials> {

  final List<Map<String, dynamic>> _requestMaterials = [];
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _loadRequestMaterials();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());

  }

  Future<void> _loadRequestMaterials() async {
    if (widget.projectId == null) return;

    final result = await sl<GetMaterialsByProjectIdUseCase>()
        .call(params: widget.projectId);

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "Erreur: $failure",
          type: SnackBarType.error,
        );
      },
          (materialsList) {
        setState(() {
          _requestMaterials.clear();
          _requestMaterials.addAll(
            (materialsList as List<Materials>).map((m) => {
              'projectId': m.projectId,
              'name': m.name,
              'unit': m.unit,
              'image': m.image,
            }),
          );
        });
      },
    );
  }

  void _addRequestMaterial() async {
    final parentContext = context;

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return AddMateriaModal(
          projectId: widget.projectId,
          onAdd: (values) async {
            // 🔴 validation
            if (values["name"] == null ||
                values["name"].toString().isEmpty ||
                values["unit"] == null ||
                values["unit"].toString().isEmpty) {
              CustomSnackBar.show(
                parentContext,
                message: "يرجى تعبئة جميع الحقول",
                type: SnackBarType.error,
              );
              return;
            }

            // ⏳ loading
            CustomSnackBar.show(
              parentContext,
              message: "جاري إضافة المادة...",
              type: SnackBarType.loading,
            );

            await Future.delayed(const Duration(milliseconds: 300));

            if (!mounted) return;

            // 🟢 ajout local
            setState(() {
              _requestMaterials.add({
                'projectId': widget.projectId,
                'name': values["name"],
                'unit': values["unit"],
                'image': values["image"],
              });
            });

            // ✅ success
            CustomSnackBar.show(
              parentContext,
              message: "تمت إضافة المادة بنجاح ✅",
              type: SnackBarType.success,
            );

            // 🔕 notification SANS navigation (IMPORTANT)
            _notificationService.send(
              title: "إضافة المادة",
              message: "تم إضافة المادة: ${values["name"]}",
              // 🚫 NE PAS mettre route
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Titre et bouton Ajouter
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: const Text(
                  "📘طلبات المواد",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addRequestMaterial,
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text("طلب المواد"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      GlobalMaterialsPdfGenerator(
                        projectId: widget.projectId,
                      ).generate(context);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                    label: const Text("تقرير شامل"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),


          const SizedBox(height: 20),

          if (_requestMaterials.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.timeline_outlined,
                      color: Colors.grey.shade400, size: 70),
                  const SizedBox(height: 8),
                  const Text(
                    "لم تتم إضافة أي مواد بعد",
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),

          ..._requestMaterials.asMap().entries.map((entry) {
            final index = entry.key;
            final material = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.1),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: TColor.primary.withOpacity(0.2),
                      child:  Icon(Icons.inventory, color: TColor.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "المادة ${index + 1} : ${material['name']}",
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  if (material['unit'] != null)
                    Row(
                      children: [
                        const Icon(Icons.straighten, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "الوحدة: ${material['unit']}",
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  if (material['image'] != null && material['image'] != "")
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            material['image'],
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

}
