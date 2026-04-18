import 'package:get/get.dart';
import '../controllers/mess_controller.dart';

class MessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessController>(() => MessController());
  }
}

