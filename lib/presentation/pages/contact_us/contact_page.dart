import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';



class ContactPage extends StatefulWidget {
  final String selectedType;

  const ContactPage({super.key, required this.selectedType});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print("Erreur ouverture URL: $e");
      CustomSnackBar.show(
        context,
        message: "تعذر فتح الرابط",
        type: SnackBarType.error,
      );
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
                    "تواصل معنا",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),


              // Card moderne avec 2 lignes x 2 colonnes et boutons plus grands
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 10,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _socialButton(
                                icon: FontAwesomeIcons.tiktok,
                                color: Colors.black,
                                label: "تيك توك",
                                url: "https://www.tiktok.com/@bhbgroup",
                                size: 48,
                              ),
                            ),
                            Expanded(
                              child: _socialButton(
                                icon: FontAwesomeIcons.whatsapp,
                                color: Colors.green,
                                label: "واتساب",
                                url: "https://wa.me/+966 56 095 2288",
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: _socialButton(
                                icon: FontAwesomeIcons.instagram,
                                color: Colors.purple,
                                label: "انستغرام",
                                url: "https://www.instagram.com/bhb50group/",
                                size: 48,
                              ),
                            ),
                            Expanded(
                              child: _socialButton(
                                icon: FontAwesomeIcons.snapchat,
                                color: Colors.yellow.shade700,
                                label: "سناب شات",
                                url: "https://www.snapchat.com/@bhb.group?invite_id=eR9b9zQc",
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 70),
                        const Text(
                          "يمكنك التواصل معنا عبر أي من الوسائل أعلاه. نحن دائمًا هنا لمساعدتك.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )


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
  Widget _socialButton({
    required IconData icon,
    required Color color,
    required String label,
    required String url,
    double size = 32, // taille par défaut
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _openUrl(url),
          borderRadius: BorderRadius.circular(60),
          splashColor: color.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.all(size * 0.4), // padding proportionnel à l'icône
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: FaIcon(icon, size: size, color: color),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

}


