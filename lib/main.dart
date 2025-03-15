import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

import 'app/pages/main_page.dart';
import 'app/middleware/auth_middleware.dart';
import 'app/bindings/app_bindings.dart';
import 'app/pages/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pcejlbysekddqzecawcz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjZWpsYnlzZWtkZHF6ZWNhd2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5ODg0MTcsImV4cCI6MjA1NzU2NDQxN30.vfsUO9fOHqrAzU2s9k8JR01Xj5HgHpGD30tu2jB3UcY',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UzzOut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF9BAB)),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      defaultTransition: Transition.fade,
      initialBinding: AppBindings(),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const OnboardingPage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/home',
          page: () => const MainPage(),
          middlewares: [AuthMiddleware()],
        ),
      ],
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const OnboardingPage());
      },
    );
  }
}
