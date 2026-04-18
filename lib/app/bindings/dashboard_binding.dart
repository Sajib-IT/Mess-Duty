import 'package:get/get.dart';
import '../controllers/mess_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/profile_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessController>(() => MessController());
    Get.lazyPut<TaskController>(() => TaskController());
    Get.lazyPut<NotificationController>(() => NotificationController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
