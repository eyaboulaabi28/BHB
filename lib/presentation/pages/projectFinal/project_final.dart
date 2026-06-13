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
import 'package:app_bhb/presentation/pages/projects/predefined_phases.dart';
import 'package:app_bhb/presentation/pages/projects/projects_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';

class ProjectFinal extends StatefulWidget {
  final String selectedType;
  final String userRole;
  final String projectName;

  const ProjectFinal({super.key, required this.selectedType,required this.userRole,required this.projectName});

  @override
  State<ProjectFinal> createState() => _ProjectFinalState();
}

class _ProjectFinalState extends State<ProjectFinal> {
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

          // 1️⃣ Filtrage par type de projet
          filteredProjects = projects
              .where((p) => p.buildingType?.contains(filterValue) == true)
              .toList();

          // 2️⃣ Filtrage par pourcentage d'avancement
          filteredProjects = filteredProjects
              .where((project) => calculateProjectProgress(project) >= 95)
              .toList();

          // 3️⃣ Si customer → afficher uniquement ses projets
          if (widget.userRole.toLowerCase() == "customer" &&
              userFirstName != null) {
            filteredProjects = filteredProjects
                .where(
                  (p) =>
              p.ownerName?.toLowerCase() ==
                  userFirstName!.toLowerCase(),
            )
                .toList();
          }
        });      },
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


  double calculateProjectProgress(Project project) {
    final stagesStatus = project.stagesStatus ?? {};

    int totalSubPhases = 0;
    double completedPoints = 0;

    for (final phase in predefinedPhasesStructure) {
      final phaseId = phase['id'] as String;

      final subPhases =
      (phase['subPhases'] as List<dynamic>? ?? []);

      totalSubPhases += subPhases.length;

      final firebasePhase =
      stagesStatus[phaseId] as Map<String, dynamic>?;

      final firebaseSubStages =
          firebasePhase?['subStages'] as Map<String, dynamic>? ?? {};

      for (final sub in subPhases) {
        final subId = sub['id'] as String;

        final status =
        firebaseSubStages[subId]?.toString().toLowerCase();

        if (status == 'terminé') {
          completedPoints += 1;
        }
      }
    }

    if (totalSubPhases == 0) return 0;

    return (completedPoints / totalSubPhases) * 100;
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
                  "إدارة المشاريع المنتهية",
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
            CustomSnackBar.show(context,
                message: "زر مخصص لإضافة محتوى جديد",
                type: SnackBarType.info);
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
  // ========  Widget de carte de projet ========
  Widget _buildProjectCard(BuildContext context, Project project) {
    final progress = calculateProjectProgress(project);

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
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: TColor.secondary.withOpacity(0.2),
                        child: Icon(Icons.apartment, color: TColor.primary, size: 30),
                      ),
                      const SizedBox(width: 12),

                      /// 👇 NOM DU PROJET SÉCURISÉ
                      Expanded(
                        child: Text(
                          project.projectName ?? "بدون اسم",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 👇 ACTIONS
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                              projectName: widget.projectName,
                            ),
                          ),
                        );
                      },
                    ),

                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Détails principaux
            //_buildInfoRow(Icons.location_on, "البلدية:", project.municipality),
            _buildInfoRow(Icons.person, "المالك:", project.ownerName),
            _buildInfoRow(Icons.badge, "رقم الرخصة:", project.licenseNumber),
            _buildInfoRow(Icons.business, "نوع المبنى:", project.buildingType),
            _buildInfoRow(Icons.date_range, "تاريخ التقرير:", project.reportDate),
            _buildInfoRow(Icons.engineering, "المهندس:", project.engineerName),
            _buildInfoRow(Icons.place, "الموقع:", project.projectAddress),

            const SizedBox(height: 10),

            // Résultat de la phase
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "نسبة الإنجاز: ${progress.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

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
