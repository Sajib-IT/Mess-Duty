import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/core/theme.dart';
import 'app/modules/auth/auth_controller.dart';
import 'app/modules/dashboard/dashboard_controller.dart';
import 'app/modules/auth/login_view.dart';
import 'app/modules/dashboard/dashboard_view.dart';
import 'app/modules/dashboard/members_view.dart';
import 'app/modules/dashboard/tasks_view.dart';
import 'app/modules/dashboard/history_view.dart';
import 'app/modules/dashboard/request_task_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize AuthController globally
  Get.put(AuthController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MessDuty',
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(
          name: '/dashboard', 
          page: () => const DashboardView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => DashboardController());
          }),
        ),
        GetPage(name: '/members', page: () => const MembersView()),
        GetPage(name: '/tasks', page: () => const TasksView()),
        GetPage(name: '/history', page: () => const HistoryView()),
        GetPage(name: '/request', page: () => const RequestTaskView()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
