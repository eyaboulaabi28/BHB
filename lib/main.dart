import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/firebase_options.dart';
import 'package:app_bhb/presentation/pages/login/splashScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' ;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bhb/presentation/bloc/roles_display.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDependencies();


  runApp(

     const MyApp(),

  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => RolesDisplay(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BHB',
        theme: ThemeData(
          fontFamily: "NotoSansArabic",
          textTheme: const TextTheme().apply(
            fontFamilyFallback: ['NotoSansArabic', 'Segoe UI Emoji'],
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: TColor.primary),
          useMaterial3: false,
        ),

        // 🔹 Définir la route initiale
        initialRoute: '/splash',

        // 🔹 Définir toutes les routes
        routes: {
          '/splash': (context) => const SplashScreen(),

          // ajouter d'autres routes ici
        },

        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ar', 'SA'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}



