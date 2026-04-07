import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/task_request_model.dart';
import '../models/task_assignment_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Operations
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<UserModel> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => UserModel.fromMap(doc.data()!, doc.id),
        );
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateUserAvailability(String uid, bool isAvailable) async {
    await _db.collection('users').doc(uid).update({'isAvailable': isAvailable});
  }

  // Task Operations
  Future<void> saveTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).set(task.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  Stream<List<TaskModel>> streamTasks() {
    return _db.collection('tasks').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateTaskRotation(String taskId, int nextIndex, DateTime lastAssigned) async {
    await _db.collection('tasks').doc(taskId).update({
      'rotationIndex': nextIndex,
      'lastAssignedAt': lastAssigned.millisecondsSinceEpoch,
    });
  }

  // Request Operations
  Future<String> createRequest(TaskRequestModel request) async {
    DocumentReference ref = await _db.collection('task_requests').add(request.toMap());
    return ref.id;
  }

  Stream<List<TaskRequestModel>> streamPendingRequests() {
    return _db
        .collection('task_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskRequestModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Assignment Operations
  Future<void> createAssignment(TaskAssignmentModel assignment) async {
    await _db.collection('task_assignments').add(assignment.toMap());
    
    // If it was from a request, update the request status
    if (assignment.requestId != null) {
      await _db.collection('task_requests').doc(assignment.requestId).update({
        'status': 'assigned',
        'assignedTo': assignment.memberId,
      });
    }
  }

  Stream<List<TaskAssignmentModel>> streamTodayAssignments() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    
    return _db
        .collection('task_assignments')
        .where('assignedAt', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskAssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<TaskAssignmentModel>> streamHistory() {
    return _db
        .collection('task_assignments')
        .orderBy('assignedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskAssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> completeAssignment(String assignmentId) async {
    await _db.collection('task_assignments').doc(assignmentId).update({
      'status': 'completed',
    });
  }
}
