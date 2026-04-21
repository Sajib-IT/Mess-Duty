import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_models.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/mess_service.dart';
import '../services/push_notification_service.dart';
import '../services/notification_service.dart' show NotificationService;
import '../utils/app_constants.dart';

class TaskController extends GetxController {
  final _taskService = Get.find<TaskService>();
  final _authService = Get.find<AuthService>();
  final _messService = Get.find<MessService>();
  PushNotificationService? get _push => Get.isRegistered<PushNotificationService>()
      ? Get.find<PushNotificationService>()
      : null;
  NotificationService? get _notif => Get.isRegistered<NotificationService>()
      ? Get.find<NotificationService>()
      : null;

  final tasks = <TaskModel>[].obs;
  final taskGroups = <TaskGroupModel>[].obs;
  final upcomingRotations = <DutyRotationModel>[].obs;
  final completionRequests = <TaskCompletionModel>[].obs;
  final members = <UserModel>[].obs;
  final isLoading = false.obs;

  String get currentUid => _authService.currentFirebaseUser?.uid ?? '';

  final isRefreshing = false.obs;

  Future<void> refresh() async {
    if (_messId == null || isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      initialize(_messId!);
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      isRefreshing.value = false;
    }
  }

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
      final totalVoters = members.where((m) => m.uid != currentUid).length;
      await _taskService.submitCompletionRequest(
        rotationId: rotation.rotationId,
        taskId: rotation.taskId,
        messId: rotation.messId,
        requestedBy: currentUid,
        totalVoters: totalVoters,
      );

      // Push notify all other members to verify
      final otherUids = members.where((m) => m.uid != currentUid).map((m) => m.uid).toList();
      final myName = members.firstWhereOrNull((m) => m.uid == currentUid)?.name ?? 'A member';
      final task = tasks.firstWhereOrNull((t) => t.taskId == rotation.taskId);
      final taskLabel = task?.displayLabel ?? 'a task';
      await _push?.sendToUsers(
        userIds: otherUids,
        title: '✅ Verify Task Completion',
        body: '$myName says they completed $taskLabel. Please verify!',
      );

      // In-app notification to all other members: completionRequest
      for (final uid in otherUids) {
        await _notif?.createInAppNotification(
          userId: uid,
          messId: rotation.messId,
          title: 'Task Completion Request',
          body: '$myName says they completed "$taskLabel". Tap to verify.',
          type: NotificationType.completionRequest,
          relatedId: rotation.rotationId,
        );
      }

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
      final isApproved = newCount / total >= 0.4;

      // In-app notification to requester
      if (isApproved) {
        final myName = members.firstWhereOrNull((m) => m.uid == currentUid)?.name ?? 'A member';
        final task = tasks.firstWhereOrNull((t) => t.taskId == completion.taskId);
        final taskLabel = task?.displayLabel ?? 'your task';
        await _notif?.createInAppNotification(
          userId: completion.requestedBy,
          messId: completion.messId,
          title: '✅ Task Approved!',
          body: '"$taskLabel" has been verified by enough members ($pct% accepted).',
          type: NotificationType.completionApproved,
          relatedId: completion.completionId,
        );
        await _push?.sendToUser(
          userId: completion.requestedBy,
          title: '✅ Task Approved!',
          body: '$myName and others verified your "$taskLabel". Great job!',
        );
      }

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
      final isRejected = newCount / total >= 0.7;
      final myName = members.firstWhereOrNull((m) => m.uid == currentUid)?.name ?? 'A member';
      final task = tasks.firstWhereOrNull((t) => t.taskId == completion.taskId);
      final taskLabel = task?.displayLabel ?? 'your task';

      if (isRejected) {
        // ── Threshold reached: task rejected / must redo ───────────────
        await _notif?.createInAppNotification(
          userId: completion.requestedBy,
          messId: completion.messId,
          title: '❌ Task Rejected',
          body: '"$taskLabel" was rejected ($pct% voted reject). Please redo it.',
          type: NotificationType.completionRejected,
          relatedId: completion.completionId,
        );
        await _push?.sendToUser(
          userId: completion.requestedBy,
          title: '❌ Task Rejected — Please Redo',
          body: 'Your "$taskLabel" was rejected by $pct% of members. Please complete it again.',
        );
      } else {
        // ── Partial reject: notify requester of progress ───────────────
        await _notif?.createInAppNotification(
          userId: completion.requestedBy,
          messId: completion.messId,
          title: '👎 Rejected by $myName',
          body: '$myName rejected your "$taskLabel" completion. ($newCount/$total rejected so far)',
          type: NotificationType.completionRequest,
          relatedId: completion.completionId,
        );
        await _push?.sendToUser(
          userId: completion.requestedBy,
          title: '👎 $myName rejected your task',
          body: '"$taskLabel": $newCount of $total rejections so far.',
        );
      }

      Get.snackbar(
        isRejected ? '❌ Task Rejected' : '👎 Rejected',
        isRejected
            ? 'Task rejected ($pct% rejected). Member must redo it.'
            : 'Your rejection recorded. ($newCount/$total rejected so far)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> createTask({
    required String label,
    required String icon,
  }) async {
    if (_messId == null) return;
    try {
      final allMemberIds = members.map((m) => m.uid).toList();
      await _taskService.createCustomTask(
        messId: _messId!,
        label: label,
        icon: icon,
        memberIds: allMemberIds,
      );
      Get.snackbar('✅ Task Created', '"$icon $label" has been added.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF7B1FA2),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> deleteTask(String taskId, String label) async {
    try {
      await _taskService.deleteTask(taskId);
      Get.snackbar('Deleted', '"$label" task removed.',
          snackPosition: SnackPosition.BOTTOM);
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

