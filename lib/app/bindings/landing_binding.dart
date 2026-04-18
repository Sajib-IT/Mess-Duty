import 'package:get/get.dart';
import '../controllers/mess_controller.dart';
import '../controllers/notification_controller.dart';

class LandingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessController>(() => MessController());
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
