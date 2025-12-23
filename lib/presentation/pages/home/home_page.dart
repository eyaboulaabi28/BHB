import 'dart:async';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/home/choose_service_screen.dart';
import 'package:app_bhb/presentation/pages/home/home_menu_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common/extension.dart';

import '../../../service_locator.dart';

class HomeScreen extends StatefulWidget {

  final String selectedType;


  const HomeScreen({super.key, required this.selectedType });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List bannerArr = [
    "assets/img/image1.png",
    "assets/img/image2.png",
    "assets/img/image3.png",
    "assets/img/image4.png",
    "assets/img/image5.png",
  ];
  PageController controller = PageController();
  int selectPage = 0;
  Timer? _bannerTimer;
  int _selectedIndex = 3;
  List<Project> allProjects = [];
  List<Project> filteredProjects = [];
  late String selectedType;
  late String userRole = '';
  late String userFirstName = '';


  String translateSelectedType(String type) {
    switch (type) {
      case "commercial":
        return "تجاري";
      case "residential":
        return "سكني";
      case "public":
        return "أماكن عامة";
      case "industrial":
        return "صناعي";
      default:
        return "";
    }
  }
  void loadProjects() async {
    final result = await sl<GetProjectUseCase>().call();

    result.fold(
          (error) => print(error),
          (projectsList) {
        final filterValue = translateSelectedType(selectedType);

        setState(() {
          allProjects = projectsList;

          filteredProjects = allProjects.where((p) =>
          p.buildingType?.contains(filterValue) == true
          ).toList();
        });
      },
    );
  }
  Map<String, String> getGreetingParts(String role, String firstName) {
    String upperName = firstName.toUpperCase();

    switch (role.toLowerCase()) {
      case 'admin':
        return {'prefix': 'بالمدير ', 'name': upperName};
      case 'engineer':
        return {'prefix': 'بالمهندس ', 'name': upperName};
      case 'customer':
        return {'prefix': 'بالعميل ', 'name': upperName};
      case 'resource':
        return {'prefix': 'بالمورد ', 'name': upperName};
      default:
        return {'prefix': 'مرحباً ', 'name': upperName};
    }
  }

  @override
  void initState() {
    super.initState();
    selectedType = widget.selectedType;
    loadProjects();
    _fetchUserRole();

    controller.addListener(() {
      setState(() {
        selectPage = controller.page?.round() ?? 0;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (controller.hasClients) {
          int nextPage = (selectPage + 1) % bannerArr.length;
          controller.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  Future<void> _fetchUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final profileResult = await AuthFirebaseServiceImpl().getUserProfile(currentUser.uid);

      setState(() {
        userRole = profileResult.fold(
              (l) => '',
              (data) => (data['role'] ?? '').toString().trim().toLowerCase(),
        );
        userFirstName = profileResult.fold(
              (l) => '',
              (data) => (data['firstName'] ?? '').toString().trim(),
        );
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'engineer':
        return Icons.engineering;
      case 'customer':
        return Icons.person;
      case 'resource':
        return Icons.handshake;
      default:
        return Icons.person_outline;
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
          automaticallyImplyLeading: false,

          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ChooseServiceScreen()),
                    (route) => false,
              );
            },
          ),
        ),

        body: Column(
          children: [
            // Header avec "الرئيسية"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  if (userFirstName.isNotEmpty && userRole.isNotEmpty)
                    Builder(
                      builder: (_) {
                        final greeting = getGreetingParts(userRole, userFirstName);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getRoleIcon(userRole),
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Tajwal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 25,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "مرحباً, ",
                                    style: TextStyle(color: Colors.white),
                                  ),

                                  // PREFIX
                                  TextSpan(
                                    text: greeting['prefix'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),

                                  // FIRST NAME (MAJ + GRAS + GRAND)
                                  TextSpan(
                                    text: greeting['name'],
                                    style: TextStyle(
                                      color: TColor.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 27,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: const Text(
                      "الرئيسية",
                      style: TextStyle(
                        fontFamily: 'Tajwal',
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: userRole.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        SizedBox(
                          height: context.width * 0.57,
                          child: PageView.builder(
                            controller: controller,
                            itemCount: bannerArr.length,
                            padEnds: false,
                            itemBuilder: (context, index) {
                              var image = bannerArr[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    image,
                                    width: context.width,
                                    height: context.width * 0.57,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: bannerArr.map((image) {
                              var index = bannerArr.indexOf(image);
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: selectPage == index ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: selectPage == index
                                        ? TColor.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    HomeMenuSection(
                      selectedType: selectedType,
                      userRole: userRole.trim().toLowerCase(),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      margin: const EdgeInsets.only(top: 15),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      width: double.maxFinite,
                    )
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
          selectedType: selectedType,
        ),
      ),
    );
  }

}
