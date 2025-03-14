import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UzzOut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.signOut();
              Get.offAllNamed('/');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => Text(
                'Welcome, ${authController.user.value?.userMetadata?['full_name'] ?? 'User'}!',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create or join a group to start swiping restaurants!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement create group functionality
                Get.snackbar(
                  'Coming Soon',
                  'Create group functionality will be implemented soon!',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Create Group'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement join group functionality
                Get.snackbar(
                  'Coming Soon',
                  'Join group functionality will be implemented soon!',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Join Group'),
            ),
          ],
        ),
      ),
    );
  }
}
