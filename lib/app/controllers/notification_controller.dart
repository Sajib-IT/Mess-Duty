import 'package:get/get.dart';
import '../models/other_models.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationController extends GetxController {
  final _notifService = Get.find<NotificationService>();
  final _authService = Get.find<AuthService>();

  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;

  String get currentUid => _authService.currentFirebaseUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (currentUid.isNotEmpty) {
      _notifService.getNotificationsStream(currentUid).listen((notifs) {
        notifications.value = notifs;
        unreadCount.value = notifs.where((n) => !n.isRead).length;
      });
    }
  }

  Future<void> markRead(String id) => _notifService.markAsRead(id);
  Future<void> markAllRead() => _notifService.markAllAsRead(currentUid);
}

