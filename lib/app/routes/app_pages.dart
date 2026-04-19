import 'package:get/get.dart';
import '../bindings/landing_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/mess_binding.dart';
import '../bindings/task_binding.dart';
import '../bindings/history_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/notification_binding.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/landing/landing_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/mess/create_mess_view.dart';
import '../views/mess/search_invite_view.dart';
import '../views/mess/mess_settings_view.dart';
import '../views/tasks/tasks_view.dart';
import '../views/tasks/task_detail_view.dart';
import '../views/tasks/task_completion_view.dart';
import '../views/history/history_view.dart';
import '../views/profile/profile_view.dart';
import '../views/notifications/notifications_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.LOGIN, page: () => const LoginView()),
    GetPage(name: Routes.SIGNUP, page: () => const SignupView()),
    GetPage(name: Routes.LANDING, page: () => const LandingView(), binding: LandingBinding()),
    GetPage(name: Routes.DASHBOARD, page: () => const DashboardView(), binding: DashboardBinding()),
    GetPage(name: Routes.CREATE_MESS, page: () => const CreateMessView(), binding: MessBinding()),
    GetPage(name: Routes.SEARCH_INVITE, page: () => const SearchInviteView(), binding: MessBinding()),
    GetPage(name: Routes.MESS_SETTINGS, page: () => const MessSettingsView(), binding: MessBinding()),
    GetPage(name: Routes.TASKS, page: () => const TasksView(), binding: TaskBinding()),
    GetPage(name: Routes.TASK_DETAIL, page: () => const TaskDetailView(), binding: TaskBinding()),
    GetPage(name: Routes.TASK_COMPLETION, page: () => const TaskCompletionView(), binding: TaskBinding()),
    GetPage(name: Routes.HISTORY, page: () => const HistoryView(), binding: HistoryBinding()),
    GetPage(name: Routes.PROFILE, page: () => const ProfileView(), binding: ProfileBinding()),
    GetPage(name: Routes.NOTIFICATIONS, page: () => const NotificationsView(), binding: NotificationBinding()),
  ];
}


