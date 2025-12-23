import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common_widget/custom_bottom_nav.dart';

class UserPage extends StatefulWidget {
  final String selectedType;

  const UserPage({super.key, required this.selectedType});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  UserCreationReq user = UserCreationReq();
  int _selectedIndex = 0;
 Map<String, Map<String, String>> roleMap = {
    "admin": {
      "title": "مدير النظام",
      "icon": "assets/img/admin.png",
    },
    "customer": {
      "title": "عميل",
      "icon": "assets/img/clients.png",
    },
    "resource": {
      "title": "مورد",
      "icon": "assets/img/resource.png",
    },
    "engineer": {
      "title": "مهندس",
      "icon": "assets/img/engineer.png",
    },
  };
  String getArabicRole(String? role) {
    if (role == null || role.isEmpty) return "";
    return roleMap[role]?["title"] ?? "";
  }
  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadCurrentUserProfile() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(fbUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          user = UserCreationReq.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
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
                    "الملف الشخصي",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ⭐ Nouveau CARD moderne
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: const AssetImage("img/profile.png"),
                      ),
                      const SizedBox(height: 15),

                      // Name
                      Text(
                        '${user.firstName ?? ''} ${user.lastName ?? ''}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Email
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[400]),

                      // Info rows
                      InfoRow(
                          icon: Icons.badge, label: "الاسم", value: user.firstName ?? ''),
                      const SizedBox(height: 5),

                      InfoRow(
                          icon: Icons.account_circle, label: "اللقب", value: user.lastName ?? ''),
                      const SizedBox(height: 5),

                      InfoRow(
                        icon: Icons.work,
                        label: "المهنة",
                        value: getArabicRole(user.role),
                      ),
                      const SizedBox(height: 5),
                      InfoRow(icon: Icons.phone, label: "رقم الهاتف", value: user.phone ?? ''),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', false);

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(email: '', password: ''),
                              ),
                                  (route) => false,
                            );
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "تسجيل الخروج",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
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

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow(
      {super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: TColor.primary),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey,fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
