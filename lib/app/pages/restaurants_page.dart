import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/animated_restaurant_card.dart';

class RestaurantsPage extends StatelessWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final RestaurantController restaurantController =
        Get.find<RestaurantController>();
    final LocationController locationController =
        Get.find<LocationController>();
    final AuthController authController = Get.find<AuthController>();

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Restaurants',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.pink.shade400,
                          ),
                          onPressed: () => locationController.refreshLocation(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    if (!authController.isAuthenticated) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.login,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Authentication required',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Get.offAllNamed('/'),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      );
                    }

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
                              onPressed:
                                  () => locationController.refreshLocation(),
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
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
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
                              return AnimatedRestaurantCard(
                                restaurant: restaurant,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
