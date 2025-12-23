import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/materials_usecases.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/materials/add_material_modal.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal;
import '../../../service_locator.dart';


class MaterialsPage extends StatefulWidget {
  final String selectedType;

  const MaterialsPage({super.key, required this.selectedType});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  int _selectedIndex = 0;
  late final GetMaterialsUseCase _getAllMaterialsUseCase;
  late final DeleteMaterialUseCase _deleteMaterialUseCase;
  late final NotificationService _notificationService;

  List<Materials> materials = [];
  List<Materials> filteredMaterials = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getAllMaterialsUseCase = sl<GetMaterialsUseCase>();
    _deleteMaterialUseCase = sl<DeleteMaterialUseCase>();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());
    _fetchMaterials();
  }

  Future<void>  _fetchMaterials() async {
    final result = await _getAllMaterialsUseCase.call();

    result.fold(
          (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $failure")),
        );
      },
          (materialsList) {
        setState(() {
          materials = List<Materials>.from(materialsList);
          filteredMaterials = materials;
        });
      },
    );
  }
  void _filterMaterials(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMaterials = materials;
      } else {
        filteredMaterials = materials
            .where((e) =>
            (e.name ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.unit ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.image ?? "").toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _deleteMaterials(String customerId) async {
    final result = await _deleteMaterialUseCase.call(params: customerId);
    final deletedCustomer =
    materials.firstWhere((e) => e.id == customerId, orElse: () => Materials());
    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "خطأ  في الحذف  : $failure",
          type: SnackBarType.error,
        );
      },
          (_) {
        setState(() {
          materials.removeWhere((e) => e.id == customerId);
        });

        CustomSnackBar.show(
          context,
          message: "تم حذف المادة بنجاح",
          type: SnackBarType.success,
        );
         _notificationService.send(
          title: "حذف مادة",
          message: "تم حذف مادة من النظام   ${deletedCustomer.name ?? ""}",
          route: "/materials",
        );
          },
    );
  }


  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF2F4F3),
        appBar: AppBar(
          backgroundColor: TColor.primary,
          elevation: 0,
          title: const SizedBox(),
        ),

        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 25, top: 20),
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Center(
                child: Text(
                  "إدارة المواد",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            CustomSearchBar(
              controller: _searchController,
              hintText: 'ابحث عن مادة...',
              onChanged: _filterMaterials,
              onFilterTap: () {
                CustomSnackBar.show(
                  context,
                  message: "ميزة الفلترة قيد التطوير ",
                  type: SnackBarType.info,
                );
              },
            ),


            const SizedBox(height: 10),

            Expanded(
              child: filteredMaterials.isEmpty
                  ? const Center(
                child: Text(
                  "لا يوجد مواد مطابقون للبحث",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredMaterials.length,
                  itemBuilder: (context, index) {
                    final material = filteredMaterials[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor:
                              TColor.secondary.withOpacity(0.2),
                              child: Icon(Icons.inventory,
                                  color: TColor.primary),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nom de la matière
                                  Text(
                                    material.name ?? "",
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Unité avec icône
                                  Row(
                                    children: [
                                      const Icon(Icons.straighten, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(
                                        material.unit ?? "",
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Titre pour l'image
                                  const Text(
                                    "صورة المادة",
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Image en petit carré
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade200,
                                      image: material.image != null && material.image!.isNotEmpty
                                          ? DecorationImage(
                                        image: NetworkImage(material.image!),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                    ),
                                    child: (material.image == null || material.image!.isEmpty)
                                        ? const Center(
                                      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                                    )
                                        : null,
                                  ),
                                ],
                              ),
                            ),





                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // Déclaration des champs pour le formulaire
                                    final
                                    fields = [
                                      generic_modal.FormFieldConfig(
                                        key: "name",
                                        hint: "اسم المادة",
                                        icon: const Icon(Icons.label, color: Colors.grey),
                                        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال اسم المادة" : null,
                                      ),
                                      generic_modal.FormFieldConfig(
                                        key: "unit",
                                        hint: "وحدة القياس",
                                        options: ["حبة", "كرتون", "لفة", "متر"],
                                        icon: const Icon(Icons.straighten, color: Colors.grey),
                                        validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار وحدة القياس" : null,
                                      ),

                                    ];

                                    final pageContext = context;

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => generic_modal.GenericFormModal(
                                        title: "تعديل المادة",
                                        submitButtonText: "حفظ",
                                        includeImagePicker: true,
                                        fields: fields,
                                        initialValues: {
                                          "id": material.id ?? "",
                                          "name": material.name ?? "",
                                          "unit": material.unit ?? "",
                                          "image": material.image ?? "",
                                        },
                                        onSubmit: (values) async {
                                          values["id"] = material.id;
                                          print("ID: ${material.id}");
                                          final updated = Materials(
                                            id: values["id"],
                                            name: values["name"],
                                            unit: values["unit"],
                                            image: values["image"],
                                          );
                                          if (updated.id == null) {
                                            print("❌ ERREUR : ID manquant dans la mise à jour");
                                            return;
                                          }
                                          final result = await sl<UpdateMaterialUseCase>().call(
                                            params: {
                                              'id': updated.id!,
                                              'material': updated,
                                            },
                                          );

                                          result.fold(
                                                (failure) {
                                              CustomSnackBar.show(
                                                pageContext,
                                                message: "خطأ أثناء التحديث ",
                                                type: SnackBarType.error,
                                              );
                                            },
                                                (_) {
                                              setState(() {
                                                final index = materials.indexWhere((e) => e.id == material.id);
                                                if (index != -1) materials[index] = updated;
                                              });

                                              CustomSnackBar.show(
                                                pageContext,
                                                message: "تم تحديث المادة بنجاح ",
                                                type: SnackBarType.success,
                                              );
                                               _notificationService.send(
                                                title: "تعديل مادة",
                                                message: "تم تعديل بيانات المادة: ${updated.name}",
                                                route: "/materials",
                                              );
                                              Navigator.of(context).pop();

                                                },
                                          );
                                        },
                                      ),
                                    );

                                  },
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                ),


                                IconButton(
                                  onPressed: () async {
                                    final confirm = await CustomDialog.show(
                                      context,
                                      title: "تأكيد الحذف",
                                      message: "هل أنت متأكد أنك تريد حذف هذه المادة ؟",
                                      type: DialogType.confirm,
                                      confirmText: "حذف",
                                      cancelText: "إلغاء",
                                    );

                                    if (confirm == true) {
                                      await _deleteMaterials(material.id!);
                                    }
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),


                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

              ),
            )

          ],
        ),

        /******************/
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddMateriaModal(
                title: "إضافة مادة جديد",
                submitButtonText: "إضافة",
                projectId:"null",
                onAdd: (values) {
                  setState(() {
                    final newMat = Materials(
                      id: values["id"],
                      name: values["name"],
                      unit: values["unit"],
                      image: values["image"],
                      projectId: "null",
                    );

                    materials.add(newMat);
                    filteredMaterials = List.from(materials); // VERY IMPORTANT
                  });
                },
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),


        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          selectedType: widget.selectedType,

        ),
      ),
    );
  }
}
