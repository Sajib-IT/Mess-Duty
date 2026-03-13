enum AssignmentStatus { pending, completed, skipped }

class TaskAssignmentModel {
  final String id;
  final String taskId;
  final String memberId;
  final DateTime assignedAt;
  final AssignmentStatus status;
  final String? requestId; // If triggered by a request

  TaskAssignmentModel({
    required this.id,
    required this.taskId,
    required this.memberId,
    required this.assignedAt,
    this.status = AssignmentStatus.pending,
    this.requestId,
  });

  factory TaskAssignmentModel.fromMap(Map<String, dynamic> data, String id) {
    return TaskAssignmentModel(
      id: id,
      taskId: data['taskId'] ?? '',
      memberId: data['memberId'] ?? '',
      assignedAt: DateTime.fromMillisecondsSinceEpoch(data['assignedAt']),
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AssignmentStatus.pending,
      ),
      requestId: data['requestId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'memberId': memberId,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
      'status': status.name,
      'requestId': requestId,
    };
  }
}
