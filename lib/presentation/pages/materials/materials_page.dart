import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/materials_usecases.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/materials/add_material_modal.dart';
import 'package:app_bhb/presentation/pages/materials/edit_material_modal.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal;
import '../../../service_locator.dart';


class MaterialsPage extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const MaterialsPage({super.key, required this.selectedType,    required this.projectName
  });

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}
class _MaterialsPageState extends State<MaterialsPage> {
  int _selectedIndex = 0;
  late final GetMaterialsUseCase _getAllMaterialsUseCase;
  late final DeleteMaterialUseCase _deleteMaterialUseCase;
  late final NotificationService _notificationService;
  List<Engineer> engineers = [];
  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold(
          (failure) => debugPrint("Erreur ingénieurs: $failure"),
          (list) => setState(() => engineers = List<Engineer>.from(list)),
    );
  }
  List<Materials> materials = [];
  List<Materials> filteredMaterials = [];

  final TextEditingController _searchController = TextEditingController();
  String getEngineerName(String? engineerId) {
    if (engineerId == null) return "";
    final eng = engineers.firstWhere((e) => e.id == engineerId, orElse: () => Engineer(id: "", firstName: "غير محدد"));
    return eng.firstName ?? "";
  }
  @override
  void initState() {
    super.initState();
    _getAllMaterialsUseCase = sl<GetMaterialsUseCase>();
    _deleteMaterialUseCase = sl<DeleteMaterialUseCase>();
    _loadEngineers();
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
        (e.description ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.unit ?? "").toLowerCase().contains(query.toLowerCase()) ||
            (e.stage ?? "").toLowerCase().contains(query.toLowerCase()))
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
          // Supprimer de la liste principale
          materials.removeWhere((e) => e.id == customerId);

          // Supprimer également de la liste filtrée
          filteredMaterials.removeWhere((e) => e.id == customerId);
        });

        CustomSnackBar.show(
          context,
          message: "تم حذف المادة بنجاح",
          type: SnackBarType.success,
        );

        _notificationService.send(
          title: "حذف مادة",
          message: "تم حذف مادة من النظام: \nالمرحلة: ${deletedCustomer.stage ?? ""}\nالوصف: ${deletedCustomer.description ?? ""}",
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
                                child:
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "مرحلة البناء: ${material.stage ?? ""}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.engineering, size: 16, color: Colors.grey),
                                        Text(
                                          " ${getEngineerName(material.engineerId)}",

                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

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

                                    // Description
                                    Row(
                                      children: [
                                        const Icon(Icons.straighten, size: 16, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(
                                          material.description ?? "",
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )

                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => EditMateriaModal(
                                        material: material,
                                        onEdit: (updatedMaterial) async {
                                          final index = materials.indexWhere((m) => m.id == updatedMaterial["id"]);
                                          if (index != -1) {
                                            // Création de l'objet Materials à mettre à jour
                                            final matToUpdate = Materials(
                                              id: updatedMaterial["id"],
                                              stage: updatedMaterial["stage"],
                                              unit: updatedMaterial["unit"],
                                              description: updatedMaterial["description"],
                                              engineerId: updatedMaterial["engineerId"],
                                              projectId: materials[index].projectId,
                                            );

                                            // 1️⃣ Mise à jour dans Firebase
                                            final result = await sl<UpdateMaterialUseCase>().call(
                                              params: {"id": matToUpdate.id!, "material": matToUpdate},
                                            );

                                            result.fold(
                                                  (failure) {
                                                CustomSnackBar.show(
                                                  context,
                                                  message: "خطأ في تعديل المادة: $failure",
                                                  type: SnackBarType.error,
                                                );
                                              },
                                                  (_) {
                                                // 2️⃣ Mise à jour locale
                                                setState(() {
                                                  materials[index] = matToUpdate;
                                                  filteredMaterials = List.from(materials);
                                                });

                                                CustomSnackBar.show(
                                                  context,
                                                  message: "تم تعديل المادة بنجاح",
                                                  type: SnackBarType.success,
                                                );
                                              },
                                            );
                                          }
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
                    // Chercher l'ingénieur correspondant
                    final eng = engineers.firstWhere(
                          (e) => e.id == values["engineerId"],
                      orElse: () => Engineer(id: "", firstName: "غير محدد"),
                    );

                    final newMat = Materials(
                      id: values["id"],
                      stage: values["stage"],
                      description: values["description"],
                      unit: values["unit"],
                      engineerId: values["engineerId"], // <- important
                      projectId: "null",
                    );

                    materials.add(newMat);
                    filteredMaterials = List.from(materials); // actualisation de la liste

                    // Si tu veux, tu peux directement remplacer le nom dans le material pour éviter getEngineerName
                    // newMat.engineerName = eng.firstName;
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
          projectName: widget.projectName,

        ),
      ),
    );
  }
}

