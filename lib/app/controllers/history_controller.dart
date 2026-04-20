import 'package:get/get.dart';
import '../models/task_models.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';

class HistoryController extends GetxController {
  final _taskService = Get.find<TaskService>();
  final _authService = Get.find<AuthService>();

  final history = <DutyRotationModel>[].obs;
  final filter = 'all'.obs; // 'all', 'mine', 'week', 'month'

  String get currentUid => _authService.currentFirebaseUser?.uid ?? '';

  void initialize(String messId) {
    _taskService.getHistoryStream(messId).listen((h) {
      history.value = h;
    });
  }

  List<DutyRotationModel> get filteredHistory {
    final now = DateTime.now();
    return history.where((r) {
      if (filter.value == 'mine' && r.assignedUserId != currentUid) return false;
      if (filter.value == 'week' && now.difference(r.scheduledDate).inDays > 7) return false;
      if (filter.value == 'month' && now.difference(r.scheduledDate).inDays > 30) return false;
      return true;
    }).toList();
  }

  Map<String, int> get dutiesPerMember {
    final map = <String, int>{};
    for (final r in history.where((h) => h.status == RotationStatus.completed)) {
      map[r.assignedUserId] = (map[r.assignedUserId] ?? 0) + 1;
    }
    return map;
  }

  /// Returns { uid → { taskId → count } } for completed duties
  Map<String, Map<String, int>> get dutiesPerMemberPerTask {
    final map = <String, Map<String, int>>{};
    for (final r in history.where((h) => h.status == RotationStatus.completed)) {
      map[r.assignedUserId] ??= {};
      map[r.assignedUserId]![r.taskId] = (map[r.assignedUserId]![r.taskId] ?? 0) + 1;
    }
    return map;
  }

  int get completedCount => history.where((r) => r.status == RotationStatus.completed).length;
  int get skippedCount => history.where((r) => r.status == RotationStatus.skipped).length;
  int get pendingCount => history.where((r) => r.status == RotationStatus.pending).length;

  double get completionRate {
    if (history.isEmpty) return 0;
    return completedCount / history.length * 100;
  }
}


