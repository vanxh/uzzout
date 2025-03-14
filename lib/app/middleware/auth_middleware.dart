import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    if (route == '/home' && !authController.isAuthenticated) {
      return const RouteSettings(name: '/');
    }

    if (route == '/' && authController.isAuthenticated) {
      return const RouteSettings(name: '/home');
    }

    return null;
  }
}
