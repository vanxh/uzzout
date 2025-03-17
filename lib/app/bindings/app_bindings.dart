import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/profile_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<LocationController>(LocationController(), permanent: true);
    Get.put<RestaurantController>(RestaurantController(), permanent: true);
    Get.put<NavigationController>(NavigationController(), permanent: true);
    Get.put<ProfileController>(ProfileController(), permanent: true);
  }
}
