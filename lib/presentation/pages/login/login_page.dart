import 'package:app_bhb/common/extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/user_signin_req.dart';
import 'package:app_bhb/domain/auth/usecases/signin.dart';
import 'package:app_bhb/presentation/pages/home/choose_service_screen.dart';
import 'package:app_bhb/presentation/pages/login/forgotpassword_page.dart';
import 'package:app_bhb/presentation/pages/login/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service_locator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  final String email;
  final String password;

  const LoginPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  bool isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose(){
    txtEmail.dispose();
    txtPassword.dispose();
    super.dispose();
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required String label,
    required String url,
    double size = 20,
  }) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint("Erreur ouverture lien: $e");
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            color: color,
            size: size,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1.1,
            child: Image.asset(
              "assets/img/bg.png",
              width: context.width,
              height: context.height,
              fit: BoxFit.fitWidth,
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/img/logoBhb.png",
                          width: context.width * 0.65,
                          fit: BoxFit.fitWidth,
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "  مرحبا بك في  ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Tajawal',
                                  fontSize: 19,
                                ),
                              ),
                              const TextSpan(
                                text: "BHB GROUP ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                  fontSize: 19,
                                ),
                              ),

                            ],
                          ),
                          textDirection: TextDirection.rtl,
                        ),

                        const SizedBox(height: 10),

                        const SizedBox(height: 15),
                        NewRoundTextField(
                          hintText: "البريد الإلكتروني",
                          keyboardType: TextInputType.emailAddress,
                          controller: txtEmail,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "الرجاء إدخال البريد الإلكتروني";
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return "البريد الإلكتروني غير صالح";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        NewRoundTextField(
                          hintText: "كلمة المرور",
                          obscureText: !isPasswordVisible,
                          right: IconButton(
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                            icon: FaIcon(
                              isPasswordVisible
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              color: TColor.primary,
                              size: 20,
                            ),
                          ),
                          controller: txtPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "الرجاء إدخال كلمة المرور";
                            }
                            if (value.length < 6) {
                              return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            // Remplace dans le onPressed du bouton ElevatedButton :
                            onPressed: isLoading
                                ? null
                                : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => isLoading = true);

                                final user = UserSigninReq(
                                  txtEmail.text.trim(),
                                  txtPassword.text.trim(),
                                );

                                final result = await sl<SigninUseCase>().call(params: user);

                                setState(() => isLoading = false);

                                result.fold(
                                      (error) {
                                        CustomSnackBar.show(
                                          context,
                                          message: error.toString(),
                                          type: SnackBarType.error,
                                          textAlignRight: true,
                                        );
                                  },
                                      (success) async {
                                    CustomSnackBar.show(
                                      context,
                                      message: "تم تسجيل الدخول بنجاح",
                                      type: SnackBarType.success,
                                      textAlignRight: true,
                                    );

                                    // ✅ Sauvegarder la session
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setBool('isLoggedIn', true);

                                    // ✅
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ChooseServiceScreen()),
                                          (route) => false,
                                    );
                                  },
                                );
                              }
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
                                  fontSize: 20, fontWeight: FontWeight.bold,fontFamily: 'Tajawal',),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.push(const ForgotpasswordPage());
                              },
                              child: Text(
                                "نسيت كلمة المرور     |",
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 14,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.push(const SignupPage());
                              },
                              child: Text(
                                "تسجيل حساب جديد",
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Text(
                          "يمكنك الاطلاع على موقعنا عبر",
                          style: TextStyle(
                            color: TColor.placeholder,
                            fontSize: 20,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 20,
                          runSpacing: 15,
                          children: [
                            _socialButton(
                              icon: FontAwesomeIcons.instagram,
                              color: Colors.purple,
                              label: "انستغرام",
                              url: "https://www.instagram.com/bhb50group/",
                              size: 20,
                            ),
                            _socialButton(
                              icon: FontAwesomeIcons.snapchat,
                              color: Colors.yellow.shade700,
                              label: "سناب شات",
                              url: "https://www.snapchat.com/@bhb.group?invite_id=eR9b9zQc",
                              size: 20,
                            ),
                            _socialButton(
                              icon: FontAwesomeIcons.tiktok,
                              color: Colors.black,
                              label: "تيك توك",
                              url: "https://www.tiktok.com/@bhbgroup",
                              size: 20,
                            ),
                            _socialButton(
                              icon: FontAwesomeIcons.whatsapp,
                              color: Colors.green,
                              label: "واتساب",
                              url: "https://wa.me/+966 56 095 2288",
                              size: 20,
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

