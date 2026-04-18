import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'app/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/auth_service.dart';
import 'app/services/mess_service.dart';
import 'app/services/task_service.dart';
import 'app/services/notification_service.dart';
import 'app/services/push_notification_service.dart';
import 'app/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register permanent services
  Get.put(AuthService(), permanent: true);
  Get.put(MessService(), permanent: true);
  Get.put(TaskService(), permanent: true);

  final notifService = NotificationService();
  Get.put(notifService, permanent: true);
  await notifService.initialize();

  Get.put(PushNotificationService(), permanent: true);

  // AuthController is permanent — manages auth state for entire app lifetime
  Get.put(AuthController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MessDuty',
      debugShowCheckedModeBanner: false,
      enableLog: true,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      initialRoute: Routes.LOGIN,
      getPages: AppPages.routes,
    );
  }
}
