import 'dart:io';

import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/source/newSite_firebase_service.dart';
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
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:app_bhb/data/auth/source/newSite_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/new_site/NewSiteProjectDetailsPage.dart';
import 'package:app_bhb/presentation/pages/new_site/addSite_tasks_modal.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_newsite.dart';
import 'package:app_bhb/presentation/pages/new_site/add_newsite_modal.dart';

class NewSiteProjectDetailsPage extends StatefulWidget {
  final String siteId; // ⚠️ ID du site
  final String selectedType;
  final String projectName;

  const NewSiteProjectDetailsPage({
    super.key,
    required this.siteId,
    required this.selectedType,
    required this.projectName,
  });

  @override
  State<NewSiteProjectDetailsPage> createState() =>
      _NewSiteProjectDetailsPageState();
}

class _NewSiteProjectDetailsPageState extends State<NewSiteProjectDetailsPage> {
  NewSite? site;
  bool isLoading = true;

  int _selectedIndex = 0;

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _fetchSiteDetails();
  }

  Future<void> _fetchSiteDetails() async {
    setState(() => isLoading = true);

    final result = await sl<NewSiteFirebaseService>().getNewSiteById(widget.siteId);

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: failure.toString(),
          type: SnackBarType.error,
        );
        setState(() => isLoading = false);
      },
          (fetchedSite) {
        site = fetchedSite;
        setState(() => isLoading = false);
      },
    );
  }

  // ⚡ Reverse geocoding pour afficher adresse lisible
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      if (kIsWeb) {
        final url = Uri.parse(
            "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=ar");
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data["display_name"] ?? "غير معروف";
        } else {
          return "غير معروف";
        }
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return "غير معروف";

      final p = placemarks.first;
      final locality = p.locality ?? "";
      final street = p.street ?? "";
      final country = p.country ?? "";
      if (locality.isEmpty && street.isEmpty && country.isEmpty) return "غير معروف";

      return "$locality - $street - $country".trim();
    } catch (e) {
      print("Reverse Geocoding Error: $e");
      return "غير معروف";
    }
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (iconColor ?? Colors.grey).withOpacity(0.2),
              child: Icon(icon, color: iconColor ?? Colors.grey),
            ),
            const SizedBox(width: 12),
            // ✅ Ici on met Expanded pour éviter l’overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // tronque si trop long
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2, // limite de lignes
                    overflow: TextOverflow.ellipsis, // tronque si trop long
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _taskDetailsWidget() {
    if (site == null || site!.task.items.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد تفاصيل للمهام",
          style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: site!.task.items.map((item) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                if (item.remark.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "ملاحظة: ${item.remark}",
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
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
                  "تفاصيل  زيارات المواقع الجديدة",
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
            // ✅ Ici, on met directement le widget conditionnel
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (site != null) ...[
                      _infoCard(
                        icon: Icons.person,
                        label: "اسم العميل",
                        value: site!.customerName ?? "-",
                        iconColor: Colors.blue,
                      ),
                      _infoCard(
                        icon: Icons.business,
                        label: "اسم المشروع",
                        value: site!.projectName ?? "-",
                        iconColor: Colors.orange,
                      ),
                      _infoCard(
                        icon: Icons.phone,
                        label: "الهاتف",
                        value: site!.phone ?? "-",
                        iconColor: Colors.green,
                      ),
                      _infoCard(
                        icon: Icons.engineering,
                        label: "المهندس",
                        value: site!.nameEngineer ?? "-",
                        iconColor: Colors.purple,
                      ),
                      if (site!.latitude != null &&
                          site!.longitude != null)
                        FutureBuilder<String>(
                          future: getAddressFromLatLng(
                              site!.latitude!, site!.longitude!),
                          builder: (context, snapshot) {
                            String value;
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              value = "جاري جلب الموقع...";
                            } else {
                              value = snapshot.data ?? "غير معروف";
                            }
                            return _infoCard(
                              icon: Icons.location_on,
                              label: "الإحداثيات",
                              value: value,
                              iconColor: Colors.red,
                            );
                          },
                        ),
                      _infoCard(
                        icon: Icons.calendar_today,
                        label: "تاريخ الإنشاء",
                        value: site!.createdAt != null
                            ? "${site!.createdAt!.day}/${site!.createdAt!.month}/${site!.createdAt!.year}"
                            : "-",
                        iconColor: Colors.teal,
                      ),
                      _infoCard(
                        icon: Icons.receipt,
                        label: "ملاحظات تقرير الاشراف",
                        value: site!.generalRemark ?? "-",
                        iconColor: Colors.teal,
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      "تفاصيل المهام:",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _taskDetailsWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            CustomSnackBar.show(
              context,
              message: "زر مخصص لإضافة محتوى جديد",
              type: SnackBarType.info,
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



