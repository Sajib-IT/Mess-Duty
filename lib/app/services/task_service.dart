import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/task_models.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class TaskService extends GetxService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> initializeDefaultTasks(String messId, List<String> memberIds) async {
    final batch = _firestore.batch();
    for (final type in TaskType.values) {
      final taskRef = _firestore.collection(Collections.tasks).doc();
      final groupRef = _firestore.collection(Collections.taskGroups).doc();

      batch.set(groupRef, {
        'taskId': taskRef.id,
        'messId': messId,
        'memberIds': memberIds,
        'currentRotationIndex': 0,
        'label': type.label,
      });

      batch.set(taskRef, {
        'messId': messId,
        'taskType': type.value,
        'groupIds': [groupRef.id],
        'isActive': true,
        'reminderTime': null,
      });
    }
    await batch.commit();
  }

  Stream<List<TaskModel>> getTasksStream(String messId) {
    return _firestore
        .collection(Collections.tasks)
        .where('messId', isEqualTo: messId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  Future<String> createCustomTask({
    required String messId,
    required String label,
    required String icon,
    required List<String> memberIds,
  }) async {
    final taskRef  = _firestore.collection(Collections.tasks).doc();
    final groupRef = _firestore.collection(Collections.taskGroups).doc();
    final batch    = _firestore.batch();
    batch.set(groupRef, {
      'taskId': taskRef.id,
      'messId': messId,
      'memberIds': memberIds,
      'currentRotationIndex': 0,
      'label': label,
    });
    batch.set(taskRef, {
      'messId': messId,
      'taskType': 'custom',
      'customLabel': label,
      'customIcon': icon,
      'groupIds': [groupRef.id],
      'isActive': true,
      'reminderTime': null,
    });
    await batch.commit();
    return taskRef.id;
  }

  Future<void> deleteTask(String taskId) async {
    // Delete all groups belonging to this task
    final groupSnap = await _firestore
        .collection(Collections.taskGroups)
        .where('taskId', isEqualTo: taskId)
        .get();

    final batch = _firestore.batch();
    for (final doc in groupSnap.docs) {
      batch.delete(doc.reference);
    }
    // Hard-delete the task document itself
    batch.delete(_firestore.collection(Collections.tasks).doc(taskId));
    await batch.commit();
  }

  Stream<List<TaskGroupModel>> getTaskGroupsStream(String messId) {
    return _firestore
        .collection(Collections.taskGroups)
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskGroupModel.fromFirestore(d)).toList());
  }

  Future<void> updateTaskGroups(String taskId, String messId, List<Map<String, dynamic>> groups) async {
    // Delete old groups for task
    final oldGroups = await _firestore
        .collection(Collections.taskGroups)
        .where('taskId', isEqualTo: taskId)
        .get();

    final batch = _firestore.batch();
    for (final doc in oldGroups.docs) {
      batch.delete(doc.reference);
    }

    final groupIds = <String>[];
    for (final g in groups) {
      final ref = _firestore.collection(Collections.taskGroups).doc();
      groupIds.add(ref.id);
      batch.set(ref, {
        'taskId': taskId,
        'messId': messId,
        'memberIds': g['memberIds'],
        'currentRotationIndex': 0,
        'label': g['label'],
      });
    }

    batch.update(_firestore.collection(Collections.tasks).doc(taskId), {'groupIds': groupIds});
    await batch.commit();
  }

  Future<DutyRotationModel?> generateNextRotation(
    TaskGroupModel group,
    List<UserModel> members,
  ) async {
    if (group.memberIds.isEmpty) return null;

    // Find next available member (not away)
    final available = group.memberIds
        .where((id) => members.any((m) => m.uid == id && !m.isAway))
        .toList();
    if (available.isEmpty) return null;

    int idx = group.currentRotationIndex % available.length;
    final assignedUserId = available[idx];
    final newIndex = (idx + 1) % available.length;

    final ref = _firestore.collection(Collections.dutyRotations).doc();
    final rotation = DutyRotationModel(
      rotationId: ref.id,
      groupId: group.groupId,
      taskId: group.taskId,
      messId: group.messId,
      assignedUserId: assignedUserId,
      scheduledDate: DateTime.now(),
      status: RotationStatus.pending,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(ref, rotation.toMap());
    batch.update(
      _firestore.collection(Collections.taskGroups).doc(group.groupId),
      {'currentRotationIndex': newIndex},
    );
    await batch.commit();
    return rotation;
  }

  Stream<List<DutyRotationModel>> getUpcomingRotationsStream(String messId) {
    return _firestore
        .collection(Collections.dutyRotations)
        .where('messId', isEqualTo: messId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DutyRotationModel.fromFirestore(d)).toList());
  }

  Stream<List<DutyRotationModel>> getHistoryStream(String messId) {
    return _firestore
        .collection(Collections.dutyRotations)
        .where('messId', isEqualTo: messId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DutyRotationModel.fromFirestore(d)).toList());
  }

  Stream<List<DutyRotationModel>> getUserRotationsStream(String uid, String messId) {
    return _firestore
        .collection(Collections.dutyRotations)
        .where('messId', isEqualTo: messId)
        .where('assignedUserId', isEqualTo: uid)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DutyRotationModel.fromFirestore(d)).toList());
  }

  Future<void> submitCompletionRequest({
    required String rotationId,
    required String taskId,
    required String messId,
    required String requestedBy,
    required int totalVoters, // total mess members excluding requester
  }) async {
    await _firestore.collection(Collections.dutyRotations).doc(rotationId).update({
      'status': 'inProgress',
    });

    final ref = _firestore.collection(Collections.taskCompletions).doc();
    await ref.set({
      'rotationId': rotationId,
      'taskId': taskId,
      'messId': messId,
      'requestedBy': requestedBy,
      'acceptedBy': [],
      'rejectedBy': [],
      'totalVoters': totalVoters,
      'requiredAcceptances': 2,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'completedAt': null,
    });
  }

  /// Accept threshold: 40% of totalVoters accepted → approved
  /// Reject threshold: 70% of totalVoters rejected → revert to pending (redo)
  Future<void> acceptCompletion({
    required String completionId,
    required String uid,
    required TaskCompletionModel completion,
    required TaskGroupModel? group,
    required List<UserModel> members,
  }) async {
    final updatedAccepted = [...completion.acceptedBy, uid];
    final total = completion.totalVoters > 0 ? completion.totalVoters : 1;
    final acceptRate = updatedAccepted.length / total;
    final batch = _firestore.batch();

    if (acceptRate >= 0.4) {
      // ✅ 40%+ accepted → task approved
      batch.update(_firestore.collection(Collections.taskCompletions).doc(completionId), {
        'acceptedBy': updatedAccepted,
        'status': 'approved',
        'completedAt': Timestamp.now(),
      });
      batch.update(_firestore.collection(Collections.dutyRotations).doc(completion.rotationId), {
        'status': 'completed',
      });
      batch.update(_firestore.collection(Collections.users).doc(completion.requestedBy), {
        'totalDutiesDone': FieldValue.increment(1),
      });
      await batch.commit();
      if (group != null) await generateNextRotation(group, members);
    } else {
      // Still accumulating votes
      batch.update(_firestore.collection(Collections.taskCompletions).doc(completionId), {
        'acceptedBy': updatedAccepted,
      });
      await batch.commit();
    }
  }

  /// Reject: track rejectedBy. If 70%+ rejected → mark rejected, revert rotation to pending (must redo)
  Future<void> rejectCompletion({
    required String completionId,
    required String uid,
    required TaskCompletionModel completion,
  }) async {
    final updatedRejected = [...completion.rejectedBy, uid];
    final total = completion.totalVoters > 0 ? completion.totalVoters : 1;
    final rejectRate = updatedRejected.length / total;
    final batch = _firestore.batch();

    if (rejectRate >= 0.7) {
      // ❌ 70%+ rejected → task failed, member must redo
      batch.update(_firestore.collection(Collections.taskCompletions).doc(completionId), {
        'rejectedBy': updatedRejected,
        'status': 'rejected',
      });
      // Revert rotation back to pending so the same person must do it again
      batch.update(_firestore.collection(Collections.dutyRotations).doc(completion.rotationId), {
        'status': 'pending',
      });
    } else {
      // Still accumulating rejections
      batch.update(_firestore.collection(Collections.taskCompletions).doc(completionId), {
        'rejectedBy': updatedRejected,
      });
    }
    await batch.commit();
  }

  Stream<List<TaskCompletionModel>> getCompletionRequestsStream(String messId) {
    return _firestore
        .collection(Collections.taskCompletions)
        .where('messId', isEqualTo: messId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskCompletionModel.fromFirestore(d)).toList());
  }
}

