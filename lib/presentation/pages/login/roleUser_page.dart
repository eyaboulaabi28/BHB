import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/domain/auth/usecases/signup.dart';
import 'package:app_bhb/presentation/pages/home/home_page.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bhb/presentation/bloc/roles_display.dart';
import 'package:app_bhb/presentation/bloc/roles_display_state.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/presentation/pages/login/login_page.dart';

class RoleuserPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phone;
  final double? latitude;
  final double? longitude;

  const RoleuserPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<RoleuserPage> createState() => _RoleuserPageState();
}

class _RoleuserPageState extends State<RoleuserPage> {

  String? selectedRole;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    context.read<RolesDisplay>().displayRoles();
  }
  final Map<String, Map<String, String>> roleData = {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 25),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: TColor.primary,
              size: 30,
              weight: 700,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1.1,
            child: Image.asset(
              "assets/img/bg.png",
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.fitWidth,
            ),
          ),

          SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    "assets/img/logoBhb.png",
                    width: MediaQuery.of(context).size.width * 0.65,
                    fit: BoxFit.fitWidth,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "اختر نوع المستخدم",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: TColor.primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- BlocBuilder des rôles ---
                  BlocBuilder<RolesDisplay, RolesDisplayState>(
                    builder: (context, state) {
                      if (state is RolesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is RolesLoadFailure) {
                        return Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (state is RolesLoaded) {
                        final roles = state.roles;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: roles.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final data = roles[index].data();
                            final roleValue =
                            (data["value"] as String).toLowerCase();

                            final roleInfo = roleData[roleValue];
                            if (roleInfo == null) return const SizedBox.shrink();

                            final isSelected = selectedRole == roleValue;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedRole = roleValue;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? TColor.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? TColor.primary
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      roleInfo["icon"]!,
                                      width: 80,
                                      height: 80,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      roleInfo["title"]!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                        color: isSelected
                                            ? Colors.white
                                            : TColor.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }

                      return const SizedBox();
                    },
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child:
                    ElevatedButton(
                      onPressed: (selectedRole == null || isLoading)
                          ? null
                          : () async {
                        setState(() => isLoading = true);

                        final user = UserCreationReq(
                          firstName:  widget.firstName,
                          lastName:  widget.lastName,
                          email: widget.email,
                          password:  widget.password,
                          phone: widget.phone,
                          role: selectedRole,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                        );

                        final result = await sl<SignupUseCase>().call(params: user);
                        setState(() => isLoading = false);

                        result.fold(
                              (error) {
                                CustomSnackBar.show(
                                  context,
                                  message: "يوجد حساب بالفعل استخدام هذا البريد الإلكتروني",
                                  type: SnackBarType.error,
                                  textAlignRight: true,
                                );
                          },
                              (success) async {
                                CustomSnackBar.show(
                                  context,
                                  message: "تم التسجيل بنجاح",
                                  type: SnackBarType.success,
                                  textAlignRight: true,
                                );

                                // 🔥 تحقق من موافقة المدير إذا الدور هو مهندس
                                if (selectedRole == "engineer") {
                                  final uid = FirebaseAuth.instance.currentUser!.uid;
                                  final userDoc = await FirebaseFirestore.instance
                                      .collection("Users")
                                      .doc(uid)
                                      .get();

                                  if (userDoc['isApproved'] == false) {
                                    CustomSnackBar.show(
                                      context,
                                      message: "في انتظار موافقة المدير على حسابك.",
                                      type: SnackBarType.error,
                                      textAlignRight: true,
                                    );
                                    return; // ❌ أوقف الإنتقال – المهندس غير مقبول بعد
                                  }
                                }
                                // Redirection selon rôle
                            Widget targetScreen;
                            switch (selectedRole) {
                              case "admin":
                                targetScreen = HomeScreen(selectedType: "admin",projectName: "");
                                break;
                              case "engineer":
                                targetScreen = HomeScreen(selectedType: "engineer",projectName: "");
                                break;
                              case "resource":
                                targetScreen = HomeScreen(selectedType: "resource",projectName: "");
                                break;
                              case "customer":
                                targetScreen = HomeScreen(selectedType: "customer",projectName: "");
                                break;
                              default:
                                targetScreen = const LoginPage(email: '', password: '');
                            }

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => targetScreen),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: isLoading
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "جاري التسجيل...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                          : const Text(
                        "تسجيل",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
