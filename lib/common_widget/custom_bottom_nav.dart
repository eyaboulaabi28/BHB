import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/presentation/pages/home/home_page.dart';
import 'package:app_bhb/presentation/pages/notification/notifications_page.dart';
import 'package:app_bhb/presentation/pages/projects/projects_page.dart';
import 'package:app_bhb/presentation/pages/users/user_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final String selectedType;
  final int notificationCount = 5;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.selectedType
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: TColor.secondary,
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 15),
                  IconButton(
                    icon: Icon(
                      Icons.person,
                      size: 34,
                      color: selectedIndex == 0
                          ? TColor.primary
                          : TColor.secondaryText,
                    ),
                    onPressed: () {
                      onTap(0);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserPage(selectedType: selectedType)),
                      );
                    },
                  ),
                  const SizedBox(width: 15),

                  // 🔔 Icône + Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications,
                          size: 34,
                          color: selectedIndex == 1
                              ? TColor.primary
                              : TColor.secondaryText,
                        ),
                        onPressed: () {
                          onTap(1);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => NotificationsPage(selectedType: selectedType)),
                          );
                        },
                      ),

                      // Badge notification
                      if (notificationCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notificationCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  const SizedBox(width: 15),
                  IconButton(
                    icon: Icon(
                      Icons.store,
                      size: 34,
                      color: selectedIndex == 2
                          ? TColor.primary
                          : TColor.secondaryText,
                    ),
                    onPressed: () async {
                      onTap(2);

                      // Récupérer le userRole
                      String userRole = '';
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final result = await AuthFirebaseServiceImpl().getUserProfile(user.uid);
                        userRole = result.fold((l) => '', (data) => data['role'] ?? '');
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectsPage(
                            selectedType: selectedType,
                            userRole: userRole, // <-- On passe le rôle ici
                          ),
                        ),
                      );
                    },

                  ),
                  const SizedBox(width: 15),
                  IconButton(
                    icon: Icon(
                      Icons.home,
                      size: 34,
                      color: selectedIndex == 3
                          ? TColor.primary
                          : TColor.secondaryText,
                    ),
                    onPressed: () async {
                      onTap(3);

                      // Récupérer le userRole avant de naviguer
                      String userRole = '';
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final result = await AuthFirebaseServiceImpl().getUserProfile(user.uid);
                        userRole = result.fold((l) => '', (data) => data['role'] ?? '');
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(
                            selectedType: selectedType,
                          ),
                        ),
                      );
                    },

                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
