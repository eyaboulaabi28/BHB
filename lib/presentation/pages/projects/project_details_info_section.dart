import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';

import '../../../service_locator.dart';

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
                      Row(
                        children: [
                          if (!isCustomer)
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.blue),
                            onPressed: onMessage,
                            tooltip: "إرسال رسالة",
                          ),
                          if (!isCustomer)
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: onCall,
                            tooltip: "إجراء مكالمة",
                          ),
                          if (!isCustomer) // n’affiche que si ce n’est pas un customer
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: onEdit,
                              tooltip: "تعديل المشروع",
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _infoRow(Icons.person, "المالك:", project.ownerName),
                  _infoRow(Icons.location_on, "البلدية:", project.municipality),
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
