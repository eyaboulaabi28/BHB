import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/presentation/pages/home/choose_service_screen.dart';
import 'package:app_bhb/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class SplashScreenPage {
  final String imagePath;
  final String englishText;
  final String arabicText;

  SplashScreenPage({
    required this.imagePath,
    required this.englishText,
    required this.arabicText,
  });
}

class _SplashScreenState extends State<SplashScreen> {
  int currentPageIndex = 0;

  List<SplashScreenPage> get pages {
    if (kIsWeb) {
      // 🌐 Web → Computer images
      return [
        SplashScreenPage(imagePath: 'assets/img/computer1.png',
            englishText: '',
            arabicText: ''),
        SplashScreenPage(imagePath: 'assets/img/computer2.png',
            englishText: '',
            arabicText: ''),
        SplashScreenPage(imagePath: 'assets/img/computer3.png',
            englishText: '',
            arabicText: ''),
      ];
    } else {
      // 📱 Mobile → Mobile images
      return [
        SplashScreenPage(imagePath: 'assets/img/mobile11.png',
            englishText: '',
            arabicText: ''),
        SplashScreenPage(imagePath: 'assets/img/mobile2.png',
            englishText: '',
            arabicText: ''),
        SplashScreenPage(imagePath: 'assets/img/mobile3.png',
            englishText: '',
            arabicText: ''),
      ];
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pages.length, (index) {
        final isActive = index == currentPageIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isActive ? 18 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive
                ? TColor.secondary
                : TColor.secondary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }



  Future<void> handleStartButton() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChooseServiceScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage(email: '', password: '')));
    }
  }
  void nextPage() async {
    // Si on est déjà sur la dernière image
    if (currentPageIndex == pages.length - 1) {
      await handleStartButton(); // 👉 Redirection
      return;
    }

    // Sinon, passer à l'image suivante
    setState(() {
      currentPageIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = pages[currentPageIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: nextPage,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                currentPage.imagePath,
                fit: kIsWeb ? BoxFit.contain : BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildDots(),
            ),
          ],
        ),
      ),
    );
  }

}