import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';

class RestaurantController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxList<Restaurant> restaurants = <Restaurant>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  // Location variables
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isLoadingLocation = false.obs;
  final Rx<String?> locationError = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    _determinePosition();
  }

  // Get the user's current position
  Future<void> _determinePosition() async {
    isLoadingLocation.value = true;
    locationError.value = null;

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, don't continue
        locationError.value = 'Location services are disabled.';
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, don't continue
          locationError.value = 'Location permissions are denied.';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        locationError.value = 'Location permissions are permanently denied.';
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      currentPosition.value = position;

      await fetchRestaurants();
    } catch (e) {
      locationError.value = 'Error getting location: ${e.toString()}';
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> fetchRestaurants() async {
    if (currentPosition.value == null) {
      errorMessage.value =
          'Location not available. Please enable location services.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final position = currentPosition.value!;

      final response = await _supabase.functions.invoke(
        'fetch-restaurants',
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'radius': 22000,
          'sort': 'distance',
        },
        headers: {
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception(
          'Failed to fetch restaurants: Status code ${response.status}',
        );
      }

      final data = response.data;
      if (data == null) {
        throw Exception('No data returned from API');
      }

      final results = data['results'] as Map<String, dynamic>;
      final List<dynamic> places = results['results'] as List<dynamic>;

      final List<Restaurant> fetchedRestaurants =
          places
              .map<Restaurant>(
                (place) =>
                    Restaurant.fromFoursquare(place as Map<String, dynamic>),
              )
              .toList();

      restaurants.value = fetchedRestaurants;
    } catch (error) {
      errorMessage.value = 'Failed to fetch restaurants: ${error.toString()}';
      print('Error fetching restaurants: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshLocation() async {
    await _determinePosition();
  }

  // Search restaurants from local list
  List<Restaurant> searchLocalRestaurants(String query) {
    if (query.isEmpty) return restaurants;

    final lowercaseQuery = query.toLowerCase();
    return restaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(lowercaseQuery) ||
          (restaurant.category?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  // Get restaurant by ID from local list
  Restaurant? getRestaurantByIdLocal(String id) {
    try {
      return restaurants.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      return null;
    }
  }
}
