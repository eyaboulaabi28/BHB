import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/projects/edit_project_modal.dart';
import 'package:app_bhb/presentation/pages/projects/project_attachments.dart';
import 'package:app_bhb/presentation/pages/projects/project_comments.dart';
import 'package:app_bhb/presentation/pages/projects/project_details_info_section.dart';
import 'package:app_bhb/presentation/pages/projects/project_employees.dart';
import 'package:app_bhb/presentation/pages/projects/project_operational_tests.dart';
import 'package:app_bhb/presentation/pages/projects/project_request_materials.dart';
import 'package:app_bhb/presentation/pages/projects/project_stages_section.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../service_locator.dart';

class ProjectsDetailsPage extends StatefulWidget {
  final String projectId;
  final String selectedType;

  const ProjectsDetailsPage({super.key, required this.projectId,required this.selectedType});

  @override
  State<ProjectsDetailsPage> createState() => _ProjectsDetailsPageState();
}

class _ProjectsDetailsPageState extends State<ProjectsDetailsPage> {
  int _selectedIndex = 0;
  int _currentStep = 0;
  Project? _project;
  bool _isLoading = true;

  late final GetProjectByIdUseCase _getProjectByIdUseCase;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _getProjectByIdUseCase = sl<GetProjectByIdUseCase>();
    _fetchProjectDetails();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());

  }

  Future<void> _fetchProjectDetails() async {
    final result = await _getProjectByIdUseCase.call(params: widget.projectId);

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "حدث خطأ أثناء تحميل تفاصيل المشروع: $failure",
          type: SnackBarType.error,
        );
        setState(() => _isLoading = false);
      },
          (project) {
        setState(() {
          _project = project;
          _isLoading = false;
        });
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _sendWhatsappMessage() async {
    final phone = _project?.phoneNumber ?? '';

    if (phone.isEmpty) {
      CustomSnackBar.show(
        context,
        message: "رقم الهاتف غير متوفر",
        type: SnackBarType.warning,
      );
      return;
    }

    // Nettoyage du numéro
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // L’URL officielle de WhatsApp
    final uri = Uri.parse("https://wa.me/$cleanedPhone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      CustomSnackBar.show(
        context,
        message: "تعذّر فتح واتساب",
        type: SnackBarType.error,
      );
    }
  }


  void _makeWhatsappCall() async {
    final phone = _project?.phoneNumber ?? '';

    if (phone.isEmpty) {
      CustomSnackBar.show(
        context,
        message: "رقم الهاتف غير متوفر",
        type: SnackBarType.warning,
      );
      return;
    }

    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    final uri = Uri.parse("https://wa.me/$cleanedPhone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      CustomSnackBar.show(
        context,
        message: "تعذّر فتح واتساب",
        type: SnackBarType.error,
      );
    }
  }


  void _editProject() {
    if (_project == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EditProjectModal(
          project: _project!,
          onSubmit: (updatedProject) {
            setState(() {
              _project = updatedProject;
            });
            CustomSnackBar.show(context, message: "تم تحديث المشروع بنجاح", type: SnackBarType.success);
             _notificationService.send(
              title: "تعديل المشروع",
              message: "تم تعديل بيانات المشروع: ${updatedProject.projectName}",
              route: "/home",
            );
          },
        );
      },
    );
  }

  // === Contenu dynamique selon l'étape ===
  Widget _buildStepContent() {
    if (_project == null) {
      return const Center(child: Text("لا توجد بيانات للمشروع"));
    }

    switch (_currentStep) {
      case 0:
        return ProjectDetailsInfoSection(
          project: _project!,
          onCall: _makeWhatsappCall,
          onMessage: _sendWhatsappMessage,
          onEdit: _editProject,
        );

      case 1:
        return ProjectStagesSection(projectId: widget.projectId);
      case 2:
        return ProjectOperationalsTest(projectId: widget.projectId);
      case 3:
        return ProjectRequestMaterials(projectId: widget.projectId);
      case 4:
        return ProjectEmployees(projectId: widget.projectId);
      case 5:
        return ProjectAttachments(projectId: widget.projectId);
      case 6:
        return ProjectComments(projectId: widget.projectId);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaceholder(String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          "$title قيد التطوير...",
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // Stepper
  Widget _buildModernStepper() {
    final steps = [
      {'icon': Icons.info_outline, 'label': 'تفاصيل'},
      {'icon': Icons.timeline, 'label': 'مراحل المشروع'},
      {'icon': Icons.science, 'label': 'اختبارات التشغيل'},
      {'icon': Icons.inventory, 'label': 'طلبات المواد'},
      {'icon': Icons.people, 'label': 'موظفي المشروع'},
      {'icon': Icons.attach_file, 'label': 'مرفقات'},
      {'icon': Icons.notes, 'label': 'ملاحظات هامة'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isActive = index == _currentStep;

            return GestureDetector(
              onTap: () {
                setState(() => _currentStep = index);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isActive
                          ? TColor.secondary
                          : Colors.grey.shade300,
                      child: Icon(
                        step['icon'] as IconData,
                        color:
                        isActive ? TColor.primary : Colors.grey.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? TColor.primary
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
            ? const Center(
          child: Text(
            "لم يتم العثور على المشروع",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        )
            : Column(
          children: [
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.only(bottom: 25, top: 20),
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Center(
                child: Text(
                  "تفاصيل المشروع",
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

          // === Stepper Moderne ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildModernStepper(),
            ),

          // === Indice visuel : glisser pour voir plus ===
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swipe, color: Colors.grey, size: 20)
                    .animate(onPlay: (controller) => controller.repeat())
                    .moveX(begin: 0, end: 10, duration: 1200.ms)
                    .then(delay: 500.ms)
                    .moveX(begin: 10, end: 0, duration: 1200.ms),
                const SizedBox(width: 6),
                const Text(
                  "اسحب لرؤية المزيد ↔️",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
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
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          selectedType: widget.selectedType,

        ),
      ),
    );
  }
}
