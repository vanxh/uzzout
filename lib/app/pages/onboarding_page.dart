import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';

import '../../main.dart' show supabase;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    _setupAuthListener();
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        Get.offAllNamed('/home');
      }
    });
  }

  Future<AuthResponse?> _handleGoogleSignIn() async {
    try {
      return _authController.signInWithGoogle();
    } catch (error) {
      _authController.errorMessage.value =
          'Failed to sign in with Google: ${error.toString()}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade100, const Color(0xFFFFF5F5)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.pink.shade200.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.1,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.pink.shade200.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 40.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant_rounded,
                                  size: 50.0,
                                  color: Color(0xFFFF9BAB),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'UzzOut',
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          'Join groups to discover and swipe through nearby restaurants together',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () =>
                          _authController.errorMessage.value != null
                              ? Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  _authController.errorMessage.value!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.red[100],
                                  ),
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            20 * (1 - _animationController.value),
                          ),
                          child: Opacity(
                            opacity: _animationController.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Obx(
                            () => _buildLoginButton(
                              context: context,
                              svgPath: 'assets/icons/google.svg',
                              text:
                                  _authController.isLoading.value
                                      ? 'Signing in...'
                                      : 'Continue with Google',
                              onPressed:
                                  _authController.isLoading.value
                                      ? null
                                      : _handleGoogleSignIn,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLoginButton(
                            context: context,
                            svgPath: 'assets/icons/apple.svg',
                            text: 'Continue with Apple',
                            onPressed: null,
                            backgroundColor: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _animationController.value,
                          child: child,
                        );
                      },
                      child: Center(
                        child: Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required String svgPath,
    required String text,
    VoidCallback? onPressed,
    Color? backgroundColor,
  }) {
    final bool isDisabled = onPressed == null;

    final Color buttonColor =
        (isDisabled
            ? backgroundColor?.withValues(alpha: 0.9)
            : backgroundColor) ??
        Colors.white;

    final Color textColor =
        isDisabled
            ? Colors.grey.shade600
            : backgroundColor != null
            ? Colors.white
            : Colors.black87;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: isDisabled ? 0 : 1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        disabledBackgroundColor: buttonColor,
        disabledForegroundColor: textColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(
            () =>
                _authController.isLoading.value && text.contains('Signing in')
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black54,
                        ),
                      ),
                    )
                    : SvgPicture.asset(
                      svgPath,
                      width: 24,
                      height: 24,
                      colorFilter:
                          isDisabled
                              ? ColorFilter.mode(
                                Colors.grey.shade600,
                                BlendMode.srcIn,
                              )
                              : backgroundColor == null
                              ? null
                              : const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                    ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
