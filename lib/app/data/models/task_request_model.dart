enum RequestStatus { pending, assigned, completed }

class TaskRequestModel {
  final String id;
  final String taskId;
  final String requestedBy;
  final RequestStatus status;
  final DateTime createdAt;
  final String? assignedTo;

  TaskRequestModel({
    required this.id,
    required this.taskId,
    required this.requestedBy,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.assignedTo,
  });

  factory TaskRequestModel.fromMap(Map<String, dynamic> data, String id) {
    return TaskRequestModel(
      id: id,
      taskId: data['taskId'] ?? '',
      requestedBy: data['requestedBy'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
      assignedTo: data['assignedTo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'requestedBy': requestedBy,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'assignedTo': assignedTo,
    };
  }
}
