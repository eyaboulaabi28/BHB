import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:flutter/material.dart';

import '../../../service_locator.dart';



class NotificationsPage extends StatefulWidget {
  final String selectedType;

  const NotificationsPage({super.key, required this.selectedType});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationsModel> notification = [];
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    final result = await sl<GetNotificationUseCase>().call();

    result.fold(
          (errorMessage) {
        CustomSnackBar.show(
          context,
          message: errorMessage,
          type: SnackBarType.error,
        );
        print(errorMessage);
      },
          (stream) {
        setState(() {
          notification = List<NotificationsModel>.from(stream);
        });
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
        appBar: AppBar(
          backgroundColor: TColor.primary,
          elevation: 0,
          title: const SizedBox(),
        ),

        body: Column(
          children: [
            // HEADER
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
                  "إدارة الإشعارات",
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

            // LISTE DES NOTIFICATIONS
            Expanded(
              child: notification.isEmpty
                  ? const Center(
                child: Text(
                  "لا توجد إشعارات",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
                  :
              ListView.builder(
                itemCount: notification.length,
                itemBuilder: (context, index) {
                  final notif = notification[index];
                  return InkWell(
                    onTap: () async {
                      // 1️⃣ Mise à jour locale
                      setState(() {
                        notif.isRead = true;
                      });

                      // 2️⃣ Mise à jour dans Firebase
                      if (notif.id != null) {
                        await sl<MarkNotificationAsReadUseCase>().call(notif.id!);
                      }

                      // 3️⃣ Navigation vers la route si existe
                      if (notif.route != null) {
                        Navigator.pushNamed(context, notif.route!);
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: "لا توجد صفحة مرتبطة بهذه الإشعار",
                          type: SnackBarType.info,
                        );
                      }
                    },

                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                      color: notif.isRead ? Colors.grey[200] : Colors.white, // <-- couleur différente
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: notif.isRead
                                  ? Colors.grey[300]
                                  : TColor.secondary.withOpacity(0.2),
                              child: Icon(Icons.notifications,
                                  color: notif.isRead ? Colors.grey : TColor.primary),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: notif.isRead ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    notif.message,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 14,
                                      color: notif.isRead ? Colors.grey : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              notif.createdAt.toString().substring(0, 16),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
              message: "زر لإضافة محتوى جديد",
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

        ),
      ),
    );
  }
}
