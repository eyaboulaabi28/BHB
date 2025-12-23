import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/round_button.dart';
import 'package:app_bhb/data/auth/models/user_creation_req.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/presentation/pages/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChooseServiceScreen extends StatefulWidget {
  const ChooseServiceScreen({super.key});

  @override
  State<ChooseServiceScreen> createState() => _ChooseServiceScreenState();
}

class _ChooseServiceScreenState extends State<ChooseServiceScreen> {
  String selectedType = "";

  UserCreationReq? currentUser;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardImageSize = screenWidth * 0.18;
    final radioSize = screenWidth * 0.07;
    final titleFontSize = screenWidth * 0.07;

    return Scaffold(
      backgroundColor: TColor.primary,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            /// Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 70),
                    /// Titre
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "مرحبًا، ",
                          style: TextStyle(
                            fontFamily: "Tajawal",
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "اختر منطقة خدمتك",
                          style: TextStyle(
                            fontFamily: "Tajawal",
                            color: TColor.secondary,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 50),

                    /// Rangées de cartes
                    Row(
                      children: [
                        _buildServiceCard(
                          label1: "مؤسسات",
                          label2: "تجارية",
                          image: "assets/img/1.png",
                          value: "commercial",
                          imgSize: cardImageSize,
                          radioSize: radioSize,
                        ),
                        const SizedBox(width: 15),
                        _buildServiceCard(
                          label1: "منازل",
                          label2: "سكنية",
                          image: "assets/img/2.png",
                          value: "residential",
                          imgSize: cardImageSize,
                          radioSize: radioSize,
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        _buildServiceCard(
                          label1: "أماكن",
                          label2: "عامة",
                          image: "assets/img/4.png",
                          value: "public",
                          imgSize: cardImageSize,
                          radioSize: radioSize,
                        ),
                        const SizedBox(width: 15),
                        _buildServiceCard(
                          label1: "أماكن",
                          label2: "صناعية",
                          image: "assets/img/5.png",
                          value: "industrial",
                          imgSize: cardImageSize,
                          radioSize: radioSize,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

           const  SizedBox(height: 50),

            /// Bouton fixé en bas
            RoundButton(
              title: "تأكيد",
              type: RoundButtonType.secondary,
              radius: 100,
              width: 300,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(selectedType: selectedType),
                  ),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Widget pour chaque carte de service
  Widget _buildServiceCard({
    required String label1,
    required String label2,
    required String image,
    required String value,
    required double imgSize,
    required double radioSize,
  }) {
    bool isSelected = selectedType == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedType = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  isSelected ? "assets/img/select_radio.png" : "assets/img/unselect_radio.png",
                  width: radioSize,
                  height: radioSize,
                ),
              ),
              SizedBox(height: 10),
              Image.asset(image, width: imgSize, height: imgSize),
              SizedBox(height: 10),
              Text(label1,
                  style: TextStyle(
                      fontFamily: "Tajawal",
                      color: TColor.primary,
                      fontSize: imgSize * 0.28)),
              Text(label2,
                  style: TextStyle(
                      fontFamily: "Tajawal",
                      color: TColor.primaryText,
                      fontSize: imgSize * 0.28)),
            ],
          ),
        ),
      ),
    );
  }
}
