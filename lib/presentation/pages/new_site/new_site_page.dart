import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:app_bhb/data/auth/source/newSite_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/new_site/NewSiteProjectDetailsPage.dart';
import 'package:app_bhb/presentation/pages/new_site/addSite_tasks_modal.dart';
import 'package:app_bhb/presentation/pages/new_site/newsite_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:printing/printing.dart';
import '../../../service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_newsite.dart';
import 'package:app_bhb/presentation/pages/new_site/add_newsite_modal.dart';


class NewSitePage extends StatefulWidget {
  final String selectedType;
  final String projectName;

  const NewSitePage({super.key, required this.selectedType,    required this.projectName
  });

  @override
  State<NewSitePage> createState() => _NewSitePageState();
}

class _NewSitePageState extends State<NewSitePage> {
  int _selectedIndex = 0;
  late final GetNewSiteUseCase _getNewSiteUseCase;
  List<NewSite> newSites = [];
  bool isLoading = true;
  late final CreateNotificationUseCase _createNotificationUseCase;
  @override
  void initState() {
    super.initState();
    _getNewSiteUseCase = sl<GetNewSiteUseCase>();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _fetchNewSites();

  }

  Future<void> _fetchNewSites() async {
    setState(() => isLoading = true);

    final result = await _getNewSiteUseCase.call();

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "خطأ في جلب زيارات المواقع",
          type: SnackBarType.error,
        );
        setState(() => isLoading = false);
      },
          (list) {
        setState(() {
          newSites = List<NewSite>.from(list);
          isLoading = false;
        });
      },
    );



  }

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

      if (locality.isEmpty && street.isEmpty && country.isEmpty) {
        return "غير معروف";
      }

      return "$locality - $street - $country".trim();
    } catch (e) {
      print("Reverse Geocoding Error: $e");
      return "غير معروف";
    }
  }

  Future<void> _sendNotification({required String title, required String message, String? route, String? userId,}) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      createdAt: DateTime.now(),
      userId: userId,
      route: route,
      isRead: false,
    );

    await _createNotificationUseCase.call(notification: notif);
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
                  "إدارة  زيارات المواقع الجديدة",
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
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : newSites.isEmpty
                  ? const Center(
                child: Text(
                  "لا توجد زيارات مواقع",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: newSites.length,
                itemBuilder: (context, index) {
                  final site = newSites[index];
                  return _newSiteCard(site);
                },
              ),
            ),

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
              builder: (context) => AddNewsiteModal(
                parentContext: context,
                title: "زيارة موقع جديد",
                onAdd: (values) {
                  setState(() {
                    newSites.add(
                      NewSite(
                        id: values["id"],
                        customerName: values["customerName"],
                        projectName: values["projectName"],
                        phone: values["phone"],
                        nameEngineer: values["nameEngineer"] ,
                        uidEngineer: values["uidEngineer"] ,
                        latitude: values["latitude"],
                        longitude: values["longitude"],
                        createdAt : values["createdAt"] ,

                        task: SiteTask(items: []),
                      ),
                    );
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
  Widget _newSiteCard(NewSite site) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 AVATAR
            CircleAvatar(
              radius: 25,
              backgroundColor: TColor.secondary.withOpacity(0.2),
              child: const Icon(Icons.location_city, color: Colors.blue),
            ),

            const SizedBox(width: 15),

            // 🟢 CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.customerName ?? "",
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (site.projectName != null && site.projectName!.isNotEmpty)
                    _infoRow(icon: Icons.business, text: site.projectName!),

                  _infoRow(icon: Icons.phone, text: site.phone ?? ""),
                  _infoRow(icon: Icons.engineering, text: site.nameEngineer ?? "غير محدد"),

                  if (site.latitude != null && site.longitude != null)
                    FutureBuilder<String>(
                      future: getAddressFromLatLng(site.latitude!, site.longitude!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Row(
                            children: const [
                              Icon(Icons.location_on, size: 16, color: Colors.grey),
                              SizedBox(width: 5),
                              Text("جاري جلب الموقع...",
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          );
                        }
                        return
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.red),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  snapshot.data ?? "غير معروف",
                                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                      },
                    ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👁️ زر التفاصيل
                IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: Colors.blue,
                    size: 26,
                  ),
                  tooltip: "عرض التفاصيل",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewSiteProjectDetailsPage(
                          projectName: site.projectName!, // ⚡ forcer le nullable
                          siteId: site.id!,                // ⚡ forcer le nullable
                          selectedType: widget.selectedType,
                        ),
                      ),
                    );
                  },
                ),
                // ➕ زر إضافة التفاصيل
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                  tooltip: "إضافة تفاصيل الزيارة",
                  onPressed: () {
                    // Vérifier si le site a déjà des tâches
                    if (site.task.items.isNotEmpty || (site.generalRemark?.isNotEmpty ?? false)) {
                      CustomSnackBar.show(
                        context,
                        message: "لقد قمت بادخال التفاصيل",
                        type: SnackBarType.warning,
                      );
                      return; // Stop, ne pas ouvrir le modal
                    }
                    if (site.id == null) {
                      CustomSnackBar.show(context,
                          message: "خطأ: لا يمكن فتح تفاصيل الموقع بدون معرف.",
                          type: SnackBarType.error);
                      return;
                    }
                    // Sinon ouvrir le modal normalement
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddSiteTasksModal(
                        siteId: site.id!,
                        site: site,
                        onSubmit: (tasks, generalRemark) async {
                          site.task.items = tasks.first.items;
                          site.generalRemark = generalRemark;

                          await sl<NewSiteFirebaseService>().updateTasksForSite(site.id!, site.task, generalRemark);

                          setState(() {}); // Rafraîchir le UI pour bloquer le bouton après ajout
                        },
                      ),
                    );
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  tooltip: "تصدير PDF",
                  onPressed: () async {
                    if (site == null) return;
                    await NewSitePdfGenerator.generate(
                      site: site,
                      context: context,
                    );
                  },
                ),



              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _infoRow({
    required IconData icon,
    required String text,
    bool bold = false,
    Color iconColor = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}

