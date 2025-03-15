import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import '../widgets/fluid_bottom_bar.dart';
import 'restaurants_page.dart';
import 'friends_page.dart';
import 'profile_page.dart';
import 'rewards_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.pink.shade200;

    final navigationController = Get.put(NavigationController());

    final pages = [
      const RestaurantsPage(),
      const FriendsPage(),
      const RewardsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: Obx(
        () => IndexedStack(
          index: navigationController.currentIndex.value,
          children: pages,
        ),
      ),
      bottomNavigationBar: FluidBottomBar(
        controller: navigationController,
        backgroundColor: Colors.white,
        selectedIconColor: Colors.white,
        unselectedIconColor: Colors.grey.shade700,
        selectedBackgroundColor: themeColor,
        items: const [
          FluidNavBarItem(icon: Icons.restaurant, label: 'Restaurants'),
          FluidNavBarItem(icon: Icons.people, label: 'Friends'),
          FluidNavBarItem(icon: Icons.card_giftcard, label: 'Rewards'),
          FluidNavBarItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}
