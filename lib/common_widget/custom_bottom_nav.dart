import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
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
  final String projectName;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.selectedType,
    required this.projectName
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: BottomAppBar(
        clipBehavior: Clip.none,
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
                        MaterialPageRoute(builder: (_) => UserPage(selectedType: selectedType,projectName: "",)),
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
                              builder: (_) =>
                                  NotificationsPage(selectedType: selectedType,projectName: projectName,),
                            ),
                          );
                        },
                      ),
                      // ✅ BADGE
                      const NotificationBadge(),

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
                            projectName: projectName,
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
                            projectName: projectName,
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


class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔐 Récupération sécurisée de l'utilisateur Firebase
    final user = FirebaseAuth.instance.currentUser;

    // ⛔ Aucun utilisateur → aucun badge
    if (user == null) {
      return const SizedBox();
    }

    return StreamBuilder<int>(
      stream: GetUnreadNotificationCountUseCase().call(user.uid),
      builder: (context, snapshot) {
        // 🔕 Pas de données ou 0 notification
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox();
        }

        // 🔔 Badge rouge
        return Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              snapshot.data.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
