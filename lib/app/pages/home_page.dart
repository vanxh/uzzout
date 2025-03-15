import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/location_controller.dart';
import '../widgets/animated_restaurant_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final RestaurantController restaurantController =
        Get.find<RestaurantController>();
    final LocationController locationController =
        Get.find<LocationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UzzOut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => locationController.refreshLocation(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.signOut();
              Get.offAllNamed('/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    'Welcome, ${authController.user.value?.userMetadata?['full_name'] ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Explore these amazing restaurants near you!',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Nearby Restaurants',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (locationController.isLoadingLocation.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Getting your location...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              if (locationController.locationError.value != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        locationController.locationError.value!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => locationController.refreshLocation(),
                        child: const Text('Enable Location'),
                      ),
                    ],
                  ),
                );
              }

              if (restaurantController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (restaurantController.errorMessage.value != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        restaurantController.errorMessage.value!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () => restaurantController.fetchRestaurants(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }

              if (restaurantController.restaurants.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_food, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No restaurants found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.85),
                      itemCount: restaurantController.restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant =
                            restaurantController.restaurants[index];
                        return AnimatedRestaurantCard(restaurant: restaurant);
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
