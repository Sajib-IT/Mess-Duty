import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/core/theme.dart';
import 'app/modules/auth/auth_controller.dart';
import 'app/modules/dashboard/dashboard_controller.dart';
import 'app/modules/auth/login_view.dart';
import 'app/modules/dashboard/dashboard_view.dart';

// Import this if you have the file, otherwise comment it out until generated
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: You must run `flutterfire configure` to generate firebase_options.dart
  // For now, we will initialize without it if not available, which might fail 
  // until the user configures it.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization failed. Please run flutterfire configure: \u0024e");
  }

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
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
