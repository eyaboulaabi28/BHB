import 'package:app_bhb/common/extension.dart';
import 'package:app_bhb/common_widget/round_button.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/domain/auth/usecases/send_password_reset.dart';
import 'package:app_bhb/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';

import '../../../service_locator.dart';


class ForgotpasswordPage extends StatefulWidget {
  const ForgotpasswordPage({super.key});

  @override
  State<ForgotpasswordPage> createState() => _ForgotpasswordPage();
}

class _ForgotpasswordPage extends State<ForgotpasswordPage> {

  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  bool isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose(){
    txtEmail.dispose();
    txtPassword.dispose();
    super.dispose();
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
                    key: _formKey, // <- on attache la clé ici
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/img/logoBhb.png",
                          width: context.width * 0.65,
                          fit: BoxFit.fitWidth,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "  نسيت كلمة المرور ",
                          style: TextStyle(
                              color: TColor.primaryText,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal'
                          ),
                        ),
                        const SizedBox(height: 10),

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
                        const SizedBox(height: 25),
                        RoundButton(
                          title: "إعادة تعيين كلمة المرور",
                          fontWeight: FontWeight.bold,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // ✅ Appel du use case
                              final result = await sl<SendPasswordUseCase>().call(params: txtEmail.text.trim());

                              result.fold(
                                    (error) {
                                  // ⛔ Affiche erreur avec un Snackbar ou un toast
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error, style: const TextStyle(fontFamily: 'Tajawal')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                    (success) {
                                  // ✅ Succès → message utilisateur
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني", style: const TextStyle(fontFamily: 'Tajawal')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // Retour à la page de connexion
                                  Future.delayed(const Duration(seconds: 2), () {
                                    context.push(const LoginPage(email: '', password: ''));
                                  });
                                },
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.push(const LoginPage(email: '',password: ''));
                              },
                              child: Text(
                                "تسجيل دخول  ",
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 15,
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
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            InkWell(onTap: () {}, child: Image.asset("assets/img/fb.png", width: 70)),
                            InkWell(onTap: () {}, child: Image.asset("assets/img/google.png", width: 70)),
                            InkWell(onTap: () {}, child: Image.asset("assets/img/in.png", width: 70)),
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


