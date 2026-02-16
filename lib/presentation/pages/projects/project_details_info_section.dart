import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';

import '../../../service_locator.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailsInfoSection extends StatelessWidget {
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
    if (project.latitude == null || project.longitude == null) return;

    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${project.latitude},${project.longitude}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
            onMessage();
            break;
          case 'call':
            onCall();
            break;
          case 'edit':
            onEdit();
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
                        child: Text(
                          project.projectName ?? "بدون اسم",
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _actionsMenu(context, isCustomer),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _infoRow(Icons.person, "المالك:", project.ownerName),
                  //_infoRow(Icons.location_on, "البلدية:", project.municipality),
                  _infoRow(Icons.badge, "رقم الرخصة:", project.licenseNumber),
                  _infoRow(Icons.apartment, "نوع المبنى:", project.buildingType),
                  _infoRow(Icons.date_range, "تاريخ التقرير:", project.reportDate),
                  _infoRow(Icons.engineering, "المهندس:", project.engineerName),
                  _infoRow(Icons.assignment_turned_in, "نتيجة المرحلة:", project.phaseResult),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
