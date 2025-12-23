import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/projects/add_project_modal.dart';
import 'package:app_bhb/presentation/pages/projects/projects_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';

class ProjectsPage extends StatefulWidget {
  final String selectedType;
  final String userRole;
  const ProjectsPage({super.key, required this.selectedType,required this.userRole,});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  int _selectedIndex = 2;
  late final GetProjectUseCase _getProjectUseCase;
  late final CreateNotificationUseCase _createNotificationUseCase;

  List<Project> projects = [];
  List<Project> filteredProjects = [];
  late String? currentUserId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getProjectUseCase = sl<GetProjectUseCase>();
    _fetchProjects();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;

  }
  Future<void> _sendNotification({required String title, required String message, String? userId, String? route,}) async {
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

  Future<void> _fetchProjects() async {
    final result = await _getProjectUseCase.call();
    if (!mounted) return;

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "خطأ أثناء تحميل المشاريع: $failure",
          type: SnackBarType.error,
        );
      },
          (list) async {
        final filterValue = translateSelectedType(widget.selectedType);
        // Récupérer le profil de l'utilisateur connecté
        final userResult = await sl<AuthFirebaseService>()
            .getUserProfile(FirebaseAuth.instance.currentUser!.uid);

        String? userFirstName;
        userResult.fold(
              (err) => null,
              (data) {
            userFirstName = data['firstName'] as String?;
          },
        );

        setState(() {
          projects = List<Project>.from(list);

          // Filtrage par type de projet
          filteredProjects = projects
              .where((p) => p.buildingType?.contains(filterValue) == true)
              .toList();

          // Si l'utilisateur est "customer", filtrer par son email
          if (widget.userRole.toLowerCase() == "customer" && userFirstName != null) {
            filteredProjects = filteredProjects
                .where((p) => p.ownerName?.toLowerCase() == userFirstName!.toLowerCase())
                .toList();
          }
        });
      },
    );
  }


  void _filterProjects(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProjects = projects;
      } else {
        filteredProjects = projects
            .where((p) =>
        (p.projectName ?? '').toLowerCase().contains(query.toLowerCase()) ||
            (p.ownerName ?? '').toLowerCase().contains(query.toLowerCase()) ||
            (p.municipality ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  String translateSelectedType(String type) {
    switch (type) {
      case "commercial":
        return "تجاري";
      case "residential":
        return "سكني";
      case "public":
        return "أماكن عامة";
      case "industrial":
        return "صناعي";
      default:
        return "";
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<void> _deleteProject(String projectId) async {
    final result = await sl<DeleteProjectUseCase>().call(params: projectId);
    final deletedCustomer =
    projects.firstWhere((e) => e.id == projectId, orElse: () => Project());

    result.fold(
            (failure) {
          CustomSnackBar.show(
            context,
            message: "خطأ  في الحذف  : $failure",
            type: SnackBarType.error,
          );
        }, (success) {
          CustomSnackBar.show(
            context,
            message: "تم حذف المشروع بنجاح",
            type: SnackBarType.success,
          );
          _sendNotification(
            title: " حذف المشروع ",
            message: "تم إضافة مشروع جديد: ${deletedCustomer.projectName}",
            userId: success,
            route: "/home",
          );
          _fetchProjects();
        },
      );

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
            // ======== Header ========
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
                  "إدارة المشاريع",
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

            // ======== Barre de recherche ========
            CustomSearchBar(
              controller: _searchController,
              hintText: 'ابحث عن مشروع...',
              onChanged: _filterProjects,
              onFilterTap: () {
                CustomSnackBar.show(
                  context,
                  message: "ميزة الفلترة قيد التطوير ",
                  type: SnackBarType.info,
                );
              },
            ),
            const SizedBox(height: 10),

            // ======== Liste des projets ========
            Expanded(
              child: filteredProjects.isEmpty
                  ? const Center(
                child: Text(
                  "لا يوجد مشاريع مطابقة للبحث",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
                  :
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  return _buildProjectCard(context, project);
                },
              ),
            ),
          ],
        ),

        // ======== Bouton flottant ========
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            if (widget.userRole.toLowerCase() == 'customer') {
              // Afficher un message pour les customers
              CustomSnackBar.show(
                context,
                message: "لا يمكن للعميل إنشاء مشروع",
                type: SnackBarType.error,
              );
              return;
            }

            // Sinon, ouvrir le modal pour ajouter un projet
            final parentContext = context;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddProjectModal(
                onSubmit: (project) async {
                  final result = await sl<AddProjectUseCase>().call(params: project);

                  result.fold(
                        (failure) {
                      CustomSnackBar.show(
                        parentContext,
                        message: "خطأ أثناء إضافة المشروع: $failure",
                        type: SnackBarType.error,
                      );
                    },
                        (success) {
                      CustomSnackBar.show(
                        parentContext,
                        message: "تم إضافة المشروع بنجاح",
                        type: SnackBarType.success,
                      );
                      _sendNotification(
                        title: "مشروع جديد",
                        message: "تم إضافة مشروع جديد: ${project.projectName}",
                        userId: success,
                        route: "/home",
                      );
                      _fetchProjects();

                      Navigator.of(context).pop();
                    },
                  );
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
  // ========  Widget de carte de projet ========
  Widget _buildProjectCard(BuildContext context, Project project) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et boutons d’action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: TColor.secondary.withOpacity(0.2),
                      child:
                      Icon(Icons.apartment, color: TColor.primary, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      project.projectName ?? "بدون اسم",
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectsDetailsPage(
                              projectId: project.id!,
                              selectedType: widget.selectedType,
                            ),
                          ),
                        );
                      },
                      tooltip: 'عرض التفاصيل',
                    ),

                    if (widget.userRole.toLowerCase() != 'customer')
                      IconButton(
                        onPressed: () async {
                          final confirm = await CustomDialog.show(
                            context,
                            title: "تأكيد الحذف",
                            message: "هل أنت متأكد أنك تريد حذف هذه المشروع ؟",
                            type: DialogType.confirm,
                            confirmText: "حذف",
                            cancelText: "إلغاء",
                          );
                          if (confirm == true) {
                            await _deleteProject(project.id!);
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                  ],
                ),

              ],
            ),

            const SizedBox(height: 10),

            // Détails principaux
            _buildInfoRow(Icons.location_on, "البلدية:", project.municipality),
            _buildInfoRow(Icons.person, "المالك:", project.ownerName),
            _buildInfoRow(Icons.badge, "رقم الرخصة:", project.licenseNumber),
            _buildInfoRow(Icons.business, "نوع المبنى:", project.buildingType),
            _buildInfoRow(Icons.date_range, "تاريخ التقرير:", project.reportDate),
            _buildInfoRow(Icons.engineering, "المهندس:", project.engineerName),
            _buildInfoRow(Icons.place, "الموقع:", project.projectAddress),

            const SizedBox(height: 10),

            // Résultat de la phase
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.phaseResult ?? "غير محدد",
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ======== Ligne d'information avec icône ========
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : "غير محدد",
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}
