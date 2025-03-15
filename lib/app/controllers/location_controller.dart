import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationController extends GetxController {
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isLoadingLocation = false.obs;
  final Rx<String?> locationError = Rx<String?>(null);
  final Rx<String?> currentAddress = Rx<String?>(null);
  final RxBool isUsingCachedData = false.obs;

  static const String _cacheKeyPrefix = 'location_cache_';
  static const String _cachePosLatKey = '${_cacheKeyPrefix}lat';
  static const String _cachePosLngKey = '${_cacheKeyPrefix}lng';
  static const String _cacheAddressKey = '${_cacheKeyPrefix}address';
  static const String _cacheTimestampKey = '${_cacheKeyPrefix}timestamp';

  static const double _maxCacheDistance = 50.0;
  static const int _cacheExpirationMs = 24 * 60 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    determinePosition();
  }

  Future<void> determinePosition() async {
    isLoadingLocation.value = true;
    locationError.value = null;
    currentAddress.value = null;
    isUsingCachedData.value = false;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'Location services are disabled.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError.value = 'Location permissions are denied.';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Location permissions are permanently denied.';
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      currentPosition.value = position;

      final cachedAddress = await _getCachedAddress(position);
      if (cachedAddress != null) {
        currentAddress.value = cachedAddress;
        isUsingCachedData.value = true;
      } else {
        await getAddressFromLatLng(position);
        isUsingCachedData.value = false;
      }
    } catch (e) {
      locationError.value = 'Error getting location: ${e.toString()}';
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<String?> _getCachedAddress(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_cacheAddressKey) ||
          !prefs.containsKey(_cachePosLatKey) ||
          !prefs.containsKey(_cachePosLngKey) ||
          !prefs.containsKey(_cacheTimestampKey)) {
        return null;
      }

      final cachedLat = prefs.getDouble(_cachePosLatKey);
      final cachedLng = prefs.getDouble(_cachePosLngKey);
      final cachedAddress = prefs.getString(_cacheAddressKey);
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedLat == null ||
          cachedLng == null ||
          cachedAddress == null ||
          cacheTimestamp == null) {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cacheTimestamp > _cacheExpirationMs) {
        return null;
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        cachedLat,
        cachedLng,
      );

      if (distance <= _maxCacheDistance) {
        return cachedAddress;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheAddress(Position position, String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble(_cachePosLatKey, position.latitude);
      await prefs.setDouble(_cachePosLngKey, position.longitude);
      await prefs.setString(_cacheAddressKey, address);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  Future<void> getAddressFromLatLng(Position position) async {
    try {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          final addressParts =
              [
                place.name,
                place.street,
                place.subLocality,
                place.locality,
                place.administrativeArea,
                place.country,
              ].where((part) => part != null && part.isNotEmpty).toList();

          if (addressParts.isNotEmpty) {
            final address = addressParts.join(', ');
            currentAddress.value = address;
            await _cacheAddress(position, address);
            return;
          }
        }
      } catch (_) {}

      try {
        final response = await http
            .get(
              Uri.parse(
                'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
              ),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['display_name'] != null) {
            final address = data['display_name'] as String;
            currentAddress.value = address;
            await _cacheAddress(position, address);
            return;
          }
        }
      } catch (_) {}

      final lat = position.latitude;
      final lng = position.longitude;
      final latDir = lat >= 0 ? 'N' : 'S';
      final lngDir = lng >= 0 ? 'E' : 'W';

      final coordAddress =
          '${lat.abs().toStringAsFixed(6)}° $latDir, ${lng.abs().toStringAsFixed(6)}° $lngDir';
      currentAddress.value = coordAddress;

      await _cacheAddress(position, coordAddress);
    } catch (e) {
      currentAddress.value = 'Location available (coordinates only)';
    }
  }

  Future<void> clearLocationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachePosLatKey);
      await prefs.remove(_cachePosLngKey);
      await prefs.remove(_cacheAddressKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {}
  }

  Future<void> refreshLocation({bool forceRefresh = false}) async {
    isUsingCachedData.value = false;
    if (forceRefresh) {
      await clearLocationCache();
    }
    await determinePosition();
  }
}
