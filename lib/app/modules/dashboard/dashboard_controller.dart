import 'package:get/get.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/task_request_model.dart';
import '../../data/models/task_assignment_model.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/rotation_service.dart';

class DashboardController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxList<TaskModel> allTasks = <TaskModel>[].obs;
  final RxList<TaskRequestModel> pendingRequests = <TaskRequestModel>[].obs;
  final RxList<TaskAssignmentModel> todayAssignments = <TaskAssignmentModel>[].obs;
  final RxList<TaskAssignmentModel> historyAssignments = <TaskAssignmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    allUsers.bindStream(_firestoreService.streamAllUsers());
    allTasks.bindStream(_firestoreService.streamTasks());
    pendingRequests.bindStream(_firestoreService.streamPendingRequests());
    todayAssignments.bindStream(_firestoreService.streamTodayAssignments());
    historyAssignments.bindStream(_firestoreService.streamHistory());
    
    // Check for daily/weekly tasks on init
    ever(allTasks, (_) {
      if (allTasks.isEmpty) {
        _initializeDefaultTasks();
      }
      _checkAndAssignPeriodicTasks();
    });
  }

  Future<void> _initializeDefaultTasks() async {
    // This is for demonstration, usually tasks would be added via UI
    final defaultTasks = [
      TaskModel(id: 'tea', title: 'Tea Making', description: 'Available on request', type: TaskType.event, membersOrder: []),
      TaskModel(id: 'water', title: 'Water Filter Refill', description: 'Available on request', type: TaskType.event, membersOrder: []),
      TaskModel(id: 'bathroom', title: 'Bathroom Cleaning', description: 'Daily task', type: TaskType.daily, membersOrder: []),
      TaskModel(id: 'basin', title: 'Basin Cleaning', description: 'Daily task', type: TaskType.daily, membersOrder: []),
      TaskModel(id: 'garbage', title: 'Garbage Disposal', description: 'Weekly task', type: TaskType.weekly, membersOrder: []),
    ];

    for (var task in defaultTasks) {
      await _firestoreService.saveTask(task);
    }
  }

  void _checkAndAssignPeriodicTasks() {
    // Only if users are loaded
    if (allUsers.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var task in allTasks) {
      bool needAssignment = false;
      
      if (task.type == TaskType.daily) {
        if (task.lastAssignedAt == null || task.lastAssignedAt!.isBefore(today)) {
          needAssignment = true;
        }
      } else if (task.type == TaskType.weekly) {
        if (task.lastAssignedAt == null || now.difference(task.lastAssignedAt!).inDays >= 7) {
          needAssignment = true;
        }
      }

      if (needAssignment) {
        _assignTask(task);
      }
    }
  }

  Future<void> requestTea() async {
    // Legacy mapping for old Tea button
    TaskModel? teaTask = allTasks.firstWhereOrNull((t) => t.title.toLowerCase().contains('tea'));
    if (teaTask != null) {
      TaskRequestModel request = TaskRequestModel(
        id: '',
        taskId: teaTask.id,
        requestedBy: Get.find<AuthController>().userModel.value?.id ?? 'system',
        createdAt: DateTime.now(),
      );
      createCustomRequest(request, teaTask);
    } else {
      Get.snackbar('Error', 'Tea task not configured');
    }
  }

  Future<void> createCustomRequest(TaskRequestModel request, TaskModel task) async {
    String requestId = await _firestoreService.createRequest(request);
    await _assignTask(task, requestId: requestId);
  }

  Future<void> _assignTask(TaskModel task, {String? requestId}) async {
    final next = RotationService.getNextAssignment(task: task, allUsers: allUsers);
    
    if (next != null) {
      String memberId = next['memberId'];
      int nextIndex = next['nextRotationIndex'];

      TaskAssignmentModel assignment = TaskAssignmentModel(
        id: '',
        taskId: task.id,
        memberId: memberId,
        assignedAt: DateTime.now(),
        requestId: requestId,
      );

      await _firestoreService.createAssignment(assignment);
      await _firestoreService.updateTaskRotation(task.id, nextIndex, DateTime.now());
      
      Get.snackbar('Task Assigned', '${task.title} assigned to ${next['memberName']}');
    } else {
      Get.snackbar('Warning', 'No available members for ${task.title}');
    }
  }

  Future<void> completeTask(String assignmentId) async {
    await _firestoreService.completeAssignment(assignmentId);
  }

  Future<void> updateTaskMembers(TaskModel task, List<String> newOrder) async {
    final updatedTask = task.copyWith(membersOrder: newOrder);
    await _firestoreService.saveTask(updatedTask);
  }

  String getUserName(String uid) {
    return allUsers.firstWhereOrNull((u) => u.id == uid)?.name ?? 'Unknown';
  }

  String getTaskTitle(String taskId) {
    return allTasks.firstWhereOrNull((t) => t.id == taskId)?.title ?? 'Task';
  }
}

// Need to import AuthController
import '../auth/auth_controller.dart';
