import 'package:get/get.dart';
import '../models/task_models.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/mess_service.dart';

class TaskController extends GetxController {
  final _taskService = Get.find<TaskService>();
  final _authService = Get.find<AuthService>();
  final _messService = Get.find<MessService>();

  final tasks = <TaskModel>[].obs;
  final taskGroups = <TaskGroupModel>[].obs;
  final upcomingRotations = <DutyRotationModel>[].obs;
  final completionRequests = <TaskCompletionModel>[].obs;
  final members = <UserModel>[].obs;
  final isLoading = false.obs;

  String get currentUid => _authService.currentFirebaseUser?.uid ?? '';

  String? _messId;

  void initialize(String messId) {
    _messId = messId;
    _taskService.getTasksStream(messId).listen((t) => tasks.value = t);
    _taskService.getTaskGroupsStream(messId).listen((g) => taskGroups.value = g);
    _taskService.getUpcomingRotationsStream(messId).listen((r) => upcomingRotations.value = r);
    _taskService.getCompletionRequestsStream(messId).listen((c) => completionRequests.value = c);
    _messService.getMembersStream(messId).listen((m) => members.value = m);
  }

  List<TaskGroupModel> getGroupsForTask(String taskId) =>
      taskGroups.where((g) => g.taskId == taskId).toList();

  DutyRotationModel? getCurrentRotationForGroup(String groupId) {
    try {
      return upcomingRotations.firstWhere((r) => r.groupId == groupId);
    } catch (_) {
      return null;
    }
  }

  Future<void> generateRotationForGroup(String groupId) async {
    try {
      final group = taskGroups.firstWhere((g) => g.groupId == groupId);
      await _taskService.generateNextRotation(group, members);
      Get.snackbar('Success', 'Rotation generated!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> submitCompletion(DutyRotationModel rotation) async {
    try {
      // Total voters = all members except the requester
      final totalVoters = members.where((m) => m.uid != currentUid).length;
      await _taskService.submitCompletionRequest(
        rotationId: rotation.rotationId,
        taskId: rotation.taskId,
        messId: rotation.messId,
        requestedBy: currentUid,
        totalVoters: totalVoters,
      );
      Get.snackbar('Request Sent', 'Waiting for member verification.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> acceptCompletion(TaskCompletionModel completion) async {
    if (completion.acceptedBy.contains(currentUid)) {
      Get.snackbar('Already Accepted', 'You already verified this task.');
      return;
    }
    if (completion.requestedBy == currentUid) {
      Get.snackbar('Not Allowed', 'You cannot accept your own request.');
      return;
    }
    try {
      final group = taskGroups.firstWhereOrNull(
        (g) => upcomingRotations.any((r) => r.rotationId == completion.rotationId && r.groupId == g.groupId),
      );
      await _taskService.acceptCompletion(
        completionId: completion.completionId,
        uid: currentUid,
        completion: completion,
        group: group,
        members: members,
      );
      final total = completion.totalVoters > 0 ? completion.totalVoters : 1;
      final newCount = completion.acceptedBy.length + 1;
      final pct = (newCount / total * 100).toStringAsFixed(0);
      Get.snackbar(
        newCount / total >= 0.4 ? '✅ Task Approved!' : 'Verified',
        newCount / total >= 0.4
            ? 'Task marked as done ($pct% accepted).'
            : 'You verified the task. ($pct% so far)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> rejectCompletion(TaskCompletionModel completion) async {
    if (completion.rejectedBy.contains(currentUid)) {
      Get.snackbar('Already Rejected', 'You already rejected this task.');
      return;
    }
    if (completion.requestedBy == currentUid) {
      Get.snackbar('Not Allowed', 'You cannot reject your own request.');
      return;
    }
    try {
      await _taskService.rejectCompletion(
        completionId: completion.completionId,
        uid: currentUid,
        completion: completion,
      );
      final total = completion.totalVoters > 0 ? completion.totalVoters : 1;
      final newCount = completion.rejectedBy.length + 1;
      final pct = (newCount / total * 100).toStringAsFixed(0);
      Get.snackbar(
        newCount / total >= 0.7 ? '❌ Task Rejected' : 'Rejected',
        newCount / total >= 0.7
            ? 'Task rejected ($pct% rejected). Member must redo it.'
            : 'Your rejection recorded. ($pct% rejected so far)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> updateTaskGroups(String taskId, List<Map<String, dynamic>> groups) async {
    if (_messId == null) return;
    await _taskService.updateTaskGroups(taskId, _messId!, groups);
    Get.snackbar('Updated', 'Task groups updated!', snackPosition: SnackPosition.BOTTOM);
  }
}

