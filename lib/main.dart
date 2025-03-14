import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UzzOut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF86C7B5)),
        fontFamily: 'Poppins',
      ),
      home: const OnboardingPage(),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF86C7B5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 50.0,
                        color: Color(0xFF86C7B5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'UzzOut',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Join groups to discover and swipe through nearby restaurants together',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLoginButton(
                    context: context,
                    svgPath: 'assets/icons/google.svg',
                    text: 'Continue with Google',
                    onPressed: () {
                      // Handle Google login
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLoginButton(
                    context: context,
                    svgPath: 'assets/icons/apple.svg',
                    text: 'Continue with Apple',
                    onPressed: () {
                      // Handle Apple login
                    },
                    backgroundColor: Colors.black,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required String svgPath,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor:
            backgroundColor != null ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 24,
            height: 24,
            colorFilter:
                backgroundColor == null
                    ? null
                    : const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
