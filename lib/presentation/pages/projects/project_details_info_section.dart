import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/presentation/pages/projects/predefined_phases.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';

import '../../../service_locator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cloud_firestore/cloud_firestore.dart';


class ProjectDetailsInfoSection extends StatefulWidget {
  final Project project;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onEdit;

  const ProjectDetailsInfoSection({
    super.key,
    required this.project,
    required this.onCall,
    required this.onMessage,
    required this.onEdit,
  });

  @override
  State<ProjectDetailsInfoSection> createState() =>
      _ProjectDetailsInfoSectionState();
}

class _ProjectDetailsInfoSectionState extends State<ProjectDetailsInfoSection> {
  bool isActiveProject = false;
  bool isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkProjectStatus();
  }

  Future<void> _checkProjectStatus() async {
    try {
      final now = DateTime.now();

      // بداية اليوم
      final startOfDay = DateTime(now.year, now.month, now.day);

      // نهاية اليوم
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where(
        'customerName',
        isEqualTo: widget.project.ownerName?.trim(),
      )
          .get();

      bool foundTodayAttendance = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final startTimeString = data['startTime'];

        if (startTimeString != null) {
          final attendanceDate = DateTime.parse(startTimeString);

          if (attendanceDate.isAfter(startOfDay) &&
              attendanceDate.isBefore(endOfDay)) {
            foundTodayAttendance = true;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        isActiveProject = foundTodayAttendance;
        isLoadingStatus = false;
      });
    } catch (e) {
      debugPrint("Project status error: $e");

      if (!mounted) return;

      setState(() {
        isActiveProject = false;
        isLoadingStatus = false;
      });
    }
  }
  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: TColor.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value ?? "غير محدد",
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProjectLocation() async {
    if (widget.project.latitude == null || widget.project.longitude == null) return;

    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${widget.project.latitude},${widget.project.longitude}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  double _calculateProjectProgress() {
    final stagesStatus = widget.project.stagesStatus ?? {};

    int totalSubPhases = 0;
    double completedPoints = 0;

    // 🔥 parcourir les 30 phases fixes
    for (final phase in predefinedPhasesStructure) {
      final phaseId = phase['id'] as String;

      final subPhases =
      (phase['subPhases'] as List<dynamic>? ?? []);

      totalSubPhases += subPhases.length;

      // récupérer phase depuis firebase
      final firebasePhase =
      stagesStatus[phaseId] as Map<String, dynamic>?;

      final firebaseSubStages =
          firebasePhase?['subStages'] as Map<String, dynamic>? ?? {};

      // 🔥 parcourir chaque sous étape
      for (final sub in subPhases) {
        final subId = sub['id'] as String;

        final status =
        firebaseSubStages[subId]?.toString().toLowerCase();

        if (status == 'terminé') {
          completedPoints += 1;
        } else if (status == 'en cours') {
          completedPoints += 0;
        }
      }
    }

    if (totalSubPhases == 0) return 0;

    return (completedPoints / totalSubPhases) * 100;
  }
  Future<String?> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final result = await sl<AuthFirebaseService>().getUserProfile(uid);

    String? role;
    result.fold(
          (err) => role = null,
          (data) => role = data['role'] as String?,
    );
    return role;
  }

  Widget _actionsMenu(BuildContext context, bool isCustomer) {
    if (isCustomer) return const SizedBox();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'location':
            _openProjectLocation();
            break;
          case 'message':
            widget.onMessage();
            break;
          case 'call':
            widget.onCall();
            break;
          case 'edit':
            widget.onEdit();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'location',
          child: ListTile(
            leading: Icon(Icons.location_on, color: Colors.red),
            title: Text("عرض موقع المشروع"),
          ),
        ),
        const PopupMenuItem(
          value: 'message',
          child: ListTile(
            leading: Icon(Icons.message, color: Colors.blue),
            title: Text("إرسال رسالة"),
          ),
        ),
        const PopupMenuItem(
          value: 'call',
          child: ListTile(
            leading: Icon(Icons.call, color: Colors.green),
            title: Text("اتصال"),
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.orange),
            title: Text("تعديل المشروع"),
          ),
        ),
      ],
    );
  }

  Widget _progressWidget() {
    final progress = _calculateProjectProgress();

    Color progressColor;

    if (progress >= 80) {
      progressColor = Colors.green;
    } else if (progress >= 40) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: progressColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: progressColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                color: progressColor,
                size: 22,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  "نسبة إنجاز المشروع",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ),

              Text(
                "${progress.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            progress >= 100
                ? "✅ تم إنجاز المشروع بالكامل"
                : progress >= 70
                ? "🚀 المشروع في مراحله النهائية"
                : progress >= 40
                ? "⚡ المشروع قيد التقدم"
                : "🛠️ المشروع في بدايته",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusWidget() {
    if (isLoadingStatus) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              height: 15,
              width: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "جاري التحقق...",
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final statusColor =
    isActiveProject ? Colors.green : Colors.red;

    final statusText =
    isActiveProject ? "المشروع نشط" : "المشروع خامل";

    final statusIcon =
    isActiveProject ? Icons.bolt : Icons.pause_circle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 8),

          Icon(
            statusIcon,
            color: statusColor,
            size: 18,
          ),

          const SizedBox(width: 6),

          Text(
            statusText,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        final userRole = snapshot.data?.toLowerCase() ?? '';
        final isCustomer = userRole == 'customer';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: TColor.primary.withOpacity(0.2),
                        child: Icon(Icons.info_outline, color: TColor.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.project.projectName ?? "بدون اسم",
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.black87,
                              ),
                            ),
                            // 🔥 الحالة الجديدة هنا
                          ],
                        ),
                      ),
                      _actionsMenu(context, isCustomer),
                    ],
                  ),

                  const SizedBox(height: 15),

                  _infoRow(Icons.person, "المالك:", widget.project.ownerName),
                  _infoRow(Icons.badge, "رقم الرخصة:", widget.project.licenseNumber),
                  _infoRow(Icons.apartment, "نوع المبنى:", widget.project.buildingType),
                  _infoRow(Icons.date_range, "تاريخ التقرير:", widget.project.reportDate),
                  _infoRow(Icons.engineering, "المهندس:", widget.project.engineerName),
                  _infoRow(Icons.assignment_turned_in, "نتيجة المرحلة:", widget.project.phaseResult),
                  const SizedBox(height: 8),
                  _statusWidget(),
                  const SizedBox(height: 12),

                  _progressWidget(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}