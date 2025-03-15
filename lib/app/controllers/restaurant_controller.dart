import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/restaurant.dart';
import 'location_controller.dart';

class RestaurantController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxList<Restaurant> restaurants = <Restaurant>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  late final LocationController locationController;

  static const String _restaurantCachePrefix = 'restaurant_cache_';
  static const String _restaurantDataKey = '${_restaurantCachePrefix}data';
  static const String _restaurantTimestampKey =
      '${_restaurantCachePrefix}timestamp';
  static const String _restaurantLocationKey =
      '${_restaurantCachePrefix}location';

  static const double _maxCacheDistance = 50.0;

  static const int _restaurantCacheExpirationMs = 30 * 60 * 1000;

  final RxBool isUsingCachedData = false.obs;

  @override
  void onInit() {
    super.onInit();
    locationController = Get.find<LocationController>();
    ever(locationController.currentPosition, (_) {
      if (locationController.currentPosition.value != null) {
        fetchRestaurants();
      }
    });
  }

  Future<List<Restaurant>?> _getCachedRestaurants(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_restaurantDataKey) ||
          !prefs.containsKey(_restaurantTimestampKey) ||
          !prefs.containsKey(_restaurantLocationKey)) {
        return null;
      }

      final cachedData = prefs.getString(_restaurantDataKey);
      final cacheTimestamp = prefs.getInt(_restaurantTimestampKey);
      final cachedLocationJson = prefs.getString(_restaurantLocationKey);

      if (cachedData == null ||
          cacheTimestamp == null ||
          cachedLocationJson == null) {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cacheTimestamp > _restaurantCacheExpirationMs) {
        return null;
      }

      final cachedLocation = json.decode(cachedLocationJson);
      final cachedLat = cachedLocation['latitude'];
      final cachedLng = cachedLocation['longitude'];

      if (cachedLat == null || cachedLng == null) {
        return null;
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        cachedLat,
        cachedLng,
      );

      if (distance <= _maxCacheDistance) {
        try {
          final List<dynamic> jsonList = json.decode(cachedData);
          return jsonList
              .map<Restaurant>((item) => Restaurant.fromJson(item))
              .toList();
        } catch (e) {
          return null;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheRestaurants(
    Position position,
    List<Restaurant> restaurants,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final restaurantJsonList = restaurants.map((r) => r.toJson()).toList();
      final restaurantJson = json.encode(restaurantJsonList);

      final locationJson = json.encode({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      await prefs.setString(_restaurantDataKey, restaurantJson);
      await prefs.setInt(
        _restaurantTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setString(_restaurantLocationKey, locationJson);
    } catch (e) {}
  }

  Future<void> clearRestaurantCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_restaurantDataKey);
      await prefs.remove(_restaurantTimestampKey);
      await prefs.remove(_restaurantLocationKey);
    } catch (e) {}
  }

  Future<void> fetchRestaurants() async {
    if (locationController.currentPosition.value == null) {
      errorMessage.value =
          'Location not available. Please enable location services.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      final position = locationController.currentPosition.value!;

      final cachedRestaurants = await _getCachedRestaurants(position);
      if (cachedRestaurants != null && cachedRestaurants.isNotEmpty) {
        restaurants.value = cachedRestaurants;
        isUsingCachedData.value = true;
        isLoading.value = false;
        return;
      }

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

      final fetchedRestaurants =
          places
              .map<Restaurant>(
                (place) =>
                    Restaurant.fromFoursquare(place as Map<String, dynamic>),
              )
              .toList();

      restaurants.value = fetchedRestaurants;
      isUsingCachedData.value = false;

      await _cacheRestaurants(position, fetchedRestaurants);
    } catch (error) {
      errorMessage.value = 'Failed to fetch restaurants: ${error.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshRestaurants({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await clearRestaurantCache();
    }
    await fetchRestaurants();
  }

  Future<Map<String, dynamic>> saveRestaurantPreference(
    String restaurantId,
    String preference,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'save-restaurant-preference',
        body: {'restaurantId': restaurantId, 'preference': preference},
        headers: {
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception(
          'Failed to save preference: Status code ${response.status}',
        );
      }

      return response.data as Map<String, dynamic>;
    } catch (error) {
      print('Error saving restaurant preference: ${error.toString()}');
      throw Exception('Failed to save preference: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> getRestaurantPreferences(
    String restaurantId,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-restaurant-preferences',
        body: {'restaurantId': restaurantId},
        headers: {
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception(
          'Failed to get restaurant preferences: Status code ${response.status}',
        );
      }

      return response.data as Map<String, dynamic>;
    } catch (error) {
      print('Error getting restaurant preferences: ${error.toString()}');
      throw Exception(
        'Failed to get restaurant preferences: ${error.toString()}',
      );
    }
  }

  List<Restaurant> searchLocalRestaurants(String query) {
    if (query.isEmpty) return restaurants;

    final lowercaseQuery = query.toLowerCase();
    return restaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(lowercaseQuery) ||
          (restaurant.category?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  Restaurant? getRestaurantByIdLocal(String id) {
    try {
      return restaurants.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      return null;
    }
  }
}
