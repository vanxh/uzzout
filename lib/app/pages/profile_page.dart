import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/location_controller.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatelessWidget {
  final Function clearAllCaches;

  const ProfilePage({super.key, this.clearAllCaches = _defaultClearAllCaches});

  static Future<void> _defaultClearAllCaches() async {
    final locationController = Get.find<LocationController>();
    final restaurantController = Get.find<RestaurantController>();
    await locationController.clearLocationCache();
    await restaurantController.clearRestaurantCache();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final LocationController locationController =
        Get.find<LocationController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final user = authController.user.value;
                  final fullName = user?.userMetadata?['full_name'] ?? 'User';
                  final email = user?.email ?? 'No email';
                  final photoUrl = user?.userMetadata?['avatar_url'];

                  return Column(
                    children: [
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.pink.shade200,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                photoUrl != null
                                    ? Image.network(photoUrl, fit: BoxFit.cover)
                                    : Center(
                                      child: Text(
                                        fullName.isNotEmpty
                                            ? fullName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ProfileInfoTile(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: fullName,
                      ),
                      const SizedBox(height: 12),
                      ProfileInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        final position =
                            locationController.currentPosition.value;
                        final isLoading =
                            locationController.isLoadingLocation.value;
                        final error = locationController.locationError.value;
                        final address = locationController.currentAddress.value;
                        final isUsingCache =
                            locationController.isUsingCachedData.value;

                        if (isLoading) {
                          return const ProfileInfoTile(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: 'Getting location...',
                            showLoading: true,
                          );
                        } else if (error != null) {
                          return ProfileInfoTile(
                            icon: Icons.location_off_outlined,
                            label: 'Location',
                            value: 'Location unavailable',
                            onTap:
                                () => locationController.refreshLocation(
                                  forceRefresh: true,
                                ),
                            trailingIcon: Icons.refresh,
                            trailingIconTooltip: 'Retry',
                          );
                        } else if (position != null) {
                          return ProfileInfoTile(
                            icon: Icons.location_on_outlined,
                            iconColor: Colors.grey.shade700,
                            label:
                                isUsingCache ? 'Location (Cached)' : 'Location',
                            value: address ?? 'Address unavailable',
                            onTap:
                                () => locationController.refreshLocation(
                                  forceRefresh: true,
                                ),
                            copyButton: true,
                            trailingIcon: Icons.refresh,
                            trailingIconTooltip: 'Force refresh',
                            onLongPress: () => _showLocationOptions(context),
                          );
                        } else {
                          return ProfileInfoTile(
                            icon: Icons.location_searching_outlined,
                            label: 'Location',
                            value: 'Tap to get location',
                            onTap: () => locationController.refreshLocation(),
                            trailingIcon: Icons.add_location_alt,
                            trailingIconTooltip: 'Get location',
                          );
                        }
                      }),
                      const SizedBox(height: 40),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await authController.signOut();
                            Get.offAllNamed('/');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 8),
                              Text('Sign Out', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final RestaurantController restaurantController = Get.find();
        final LocationController locationController = Get.find();
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Location Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Obx(
                () =>
                    locationController.isUsingCachedData.value
                        ? ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade400,
                          ),
                          title: const Text('Using Cached Data'),
                          subtitle: const Text(
                            'Location and restaurant data is from cache',
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh Location'),
                subtitle: const Text(
                  'Get your current location (uses cache if valid)',
                ),
                onTap: () {
                  Navigator.pop(context);
                  locationController.refreshLocation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Force Refresh Everything'),
                subtitle: const Text('Clear all caches and get fresh data'),
                onTap: () {
                  Navigator.pop(context);
                  locationController.refreshLocation(forceRefresh: true);
                  restaurantController.refreshRestaurants(forceRefresh: true);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Refresh Restaurants Only'),
                subtitle: const Text(
                  'Get fresh restaurant data for current location',
                ),
                onTap: () {
                  Navigator.pop(context);
                  restaurantController.refreshRestaurants();
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: const Text('Force Refresh Restaurants'),
                subtitle: const Text('Clear restaurant cache and get new data'),
                onTap: () {
                  Navigator.pop(context);
                  restaurantController.refreshRestaurants(forceRefresh: true);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear All Caches'),
                subtitle: const Text(
                  'Remove all stored location and restaurant data',
                ),
                onTap: () {
                  Navigator.pop(context);
                  clearAllCaches();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All caches cleared'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showLoading;
  final bool copyButton;
  final IconData? trailingIcon;
  final String? trailingIconTooltip;
  final VoidCallback? onLongPress;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
    this.showLoading = false,
    this.copyButton = false,
    this.trailingIcon,
    this.trailingIconTooltip,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 80),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.pink.shade300,
                            ),
                          ),
                        ),
                      if (copyButton && !showLoading)
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () {
                            final data = ClipboardData(text: value);
                            Clipboard.setData(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (onTap != null && !showLoading && !copyButton)
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
