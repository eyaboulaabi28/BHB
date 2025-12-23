import 'package:app_bhb/common/extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/round_button.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:app_bhb/presentation/pages/login/login_page.dart';
import 'package:app_bhb/presentation/pages/login/roleUser_page.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key,});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  TextEditingController txtFirstName = TextEditingController();
  TextEditingController txtLastName = TextEditingController();
  TextEditingController txtPhone = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtLocation = TextEditingController();
  final GlobalKey<FormFieldState<String>> _locationFieldKey = GlobalKey<FormFieldState<String>>();

  double? latitude;
  double? longitude;
  bool isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose(){
    txtFirstName.dispose();
    txtLastName.dispose();
    txtEmail.dispose();
    txtPassword.dispose();
    txtPhone.dispose();
    txtLocation.dispose();
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
                          const SizedBox(height: 20),
                          Text(
                            "تسجيل حساب جديد",
                            style: TextStyle(
                              color: TColor.primaryText,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),
                          NewRoundTextField(
                            hintText: "الاسم الأول",
                            controller: txtFirstName,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "الرجاء إدخال الاسم الأول";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          NewRoundTextField(
                            hintText: "اسم العائلة",
                            controller: txtLastName,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "الرجاء إدخال اسم العائلة";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          NewRoundTextField(
                            hintText: "رقم هاتف",
                            controller: txtPhone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "الرجاء إدخال اسم رقم هاتف";
                              }
                              return null;
                            },
                          ),
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
                          const SizedBox(height: 15,),
                          NewRoundTextField(
                            key: _locationFieldKey,
                            hintText: "الموقع",
                            controller: txtLocation,
                            readOnly: true,
                            maxLines: 3,
                            right: Icon(Icons.location_on, color: TColor.primary),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "الرجاء اختيار الموقع";
                              }
                              return null;
                            },
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SelectLocationMap()),
                              );

                              if (result != null) {
                                setState(() {
                                  txtLocation.text = result["address"];
                                  latitude = result["lat"];
                                  longitude = result["lng"];
                                });

                                // 🔥 هذا السطر هو الحل
                                _locationFieldKey.currentState
                                    ?.didChange(result["address"]);
                              }
                            },
                          ),
                          const SizedBox(height: 25),
                          RoundButton(
                            title: "متابعة",
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.push(RoleuserPage(
                                  firstName: txtFirstName.text,
                                  lastName: txtLastName.text,
                                  email: txtEmail.text,
                                  password: txtPassword.text,
                                  phone: txtPhone.text,
                                  latitude: latitude,
                                  longitude: longitude,                                ));
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  message: "الرجاء التحقق من الحقول وإعادة المحاولة",
                                  type: SnackBarType.error,
                                  textAlignRight: true,


                                );
                              }
                            },
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
                          const SizedBox(height: 25),
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

                          const SizedBox(height: 25),
                          TextButton(
                            onPressed: () {
                              context.push(const LoginPage(email: '',password: ''));
                            },
                            child: Text(
                              "لديك حساب بالفعل؟",
                              style: TextStyle(
                                color: TColor.primaryText,
                                fontSize: 20,
                                fontFamily: 'Tajawal',
                              ),
                            ),
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


